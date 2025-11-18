import sys
import os
import json
import re
import subprocess
from pathlib import Path
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QSplitter,
    QPlainTextEdit, QTextEdit, QToolBar, QFileDialog, QMessageBox,
    QMenu, QMenuBar, QStatusBar, QDialog, QLabel, QLineEdit, QPushButton, QHBoxLayout
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QObject, QRect, QSize
from PyQt6.QtGui import (
    QSyntaxHighlighter, QTextCharFormat, QColor, QFont, QPainter, QTextFormat, QAction, QIcon, QKeySequence
)
from PyQt6.QtWidgets import QProgressDialog

APP_DIR = Path(__file__).parent
SETTINGS_FILE = APP_DIR / "settings.json"


def load_settings():
    if SETTINGS_FILE.exists():
        try:
            return json.loads(SETTINGS_FILE.read_text(encoding='utf-8'))
        except Exception:
            return {}
    return {}


def save_settings(d):
    SETTINGS_FILE.write_text(json.dumps(d, indent=2), encoding='utf-8')


class LineNumberArea(QWidget):
    def __init__(self, editor):
        super().__init__(editor)
        self._editor = editor

    def sizeHint(self) -> QSize:
        return QSize(self._editor.lineNumberAreaWidth(), 0)

    def paintEvent(self, event):
        self._editor.lineNumberAreaPaintEvent(event)


class CodeEditor(QPlainTextEdit):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.lineNumberArea = LineNumberArea(self)
        self.blockCountChanged.connect(self.updateLineNumberAreaWidth)
        self.updateRequest.connect(self.updateLineNumberArea)
        self.cursorPositionChanged.connect(self.highlightCurrentLine)
        self.updateLineNumberAreaWidth(0)

    def lineNumberAreaWidth(self):
        digits = max(1, len(str(max(1, self.blockCount()))))
        space = 8 + self.fontMetrics().horizontalAdvance('9') * digits
        return space

    def updateLineNumberAreaWidth(self, _):
        self.setViewportMargins(self.lineNumberAreaWidth(), 0, 0, 0)

    def updateLineNumberArea(self, rect, dy):
        if dy:
            self.lineNumberArea.scroll(0, dy)
        else:
            self.lineNumberArea.update(0, rect.y(), self.lineNumberArea.width(), rect.height())

        if rect.contains(self.viewport().rect()):
            self.updateLineNumberAreaWidth(0)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        cr = self.contentsRect()
        self.lineNumberArea.setGeometry(QRect(cr.left(), cr.top(), self.lineNumberAreaWidth(), cr.height()))

    def lineNumberAreaPaintEvent(self, event):
        painter = QPainter(self.lineNumberArea)
        painter.fillRect(event.rect(), QColor('#F5F5F5'))

        block = self.firstVisibleBlock()
        blockNumber = block.blockNumber()
        top = int(self.blockBoundingGeometry(block).translated(self.contentOffset()).top())
        bottom = top + int(self.blockBoundingRect(block).height())

        fm = self.fontMetrics()
        while block.isValid() and top <= event.rect().bottom():
            if block.isVisible() and bottom >= event.rect().top():
                number = str(blockNumber + 1)
                painter.setPen(QColor('#666666'))
                painter.drawText(0, top, self.lineNumberArea.width() - 4, fm.height(), Qt.AlignmentFlag.AlignRight, number)

            block = block.next()
            top = bottom
            bottom = top + int(self.blockBoundingRect(block).height())
            blockNumber += 1

    def highlightCurrentLine(self):
        extraSelections = []
        if not self.isReadOnly():
            selection = QTextEdit.ExtraSelection()
            lineColor = QColor('#FFF4C2')
            selection.format.setBackground(lineColor)
            selection.cursor = self.textCursor()
            selection.cursor.clearSelection()
            extraSelections.append(selection)
        self.setExtraSelections(extraSelections)


class VerilogHighlighter(QSyntaxHighlighter):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.highlightingRules = []

        keywordFormat = QTextCharFormat()
        keywordFormat.setForeground(QColor('#000080'))
        keywordFormat.setFontWeight(QFont.Weight.Bold)
        keywords = [
            'module', 'endmodule', 'input', 'output', 'inout', 'wire', 'reg', 'always', 'assign',
            'if', 'else', 'for', 'begin', 'end', 'initial', 'parameter'
        ]
        for word in keywords:
            pattern = f"\\b{word}\\b"
            self.highlightingRules.append((pattern, keywordFormat))

        numberFormat = QTextCharFormat()
        numberFormat.setForeground(QColor('#008000'))
        self.highlightingRules.append((r"\b[0-9]+\b", numberFormat))

        stringFormat = QTextCharFormat()
        stringFormat.setForeground(QColor('#B22222'))
        self.highlightingRules.append((r'".*"', stringFormat))

        commentFormat = QTextCharFormat()
        commentFormat.setForeground(QColor('#808080'))
        self.commentStartExpression = r'/\*'
        self.commentEndExpression = r'\*/'
        self.commentFormat = commentFormat

        self.lineCommentRegex = r'//.*'

    def highlightBlock(self, text):
        for pattern, fmt in self.highlightingRules:
            import re
            for m in re.finditer(pattern, text):
                start, end = m.span()
                self.setFormat(start, end - start, fmt)

        # line comments
        import re
        for m in re.finditer(self.lineCommentRegex, text):
            start, end = m.span()
            self.setFormat(start, end - start, self.commentFormat)

        # block comments (simple handling)
        self.setCurrentBlockState(0)
        startIndex = 0
        if self.previousBlockState() != 1:
            startIndex = text.find('/*')

        while startIndex >= 0:
            endIndex = text.find('*/', startIndex + 2)
            if endIndex == -1:
                self.setCurrentBlockState(1)
                commentLength = len(text) - startIndex
                self.setFormat(startIndex, commentLength, self.commentFormat)
                break
            else:
                commentLength = endIndex - startIndex + 2
                self.setFormat(startIndex, commentLength, self.commentFormat)
                startIndex = text.find('/*', endIndex + 2)


class AIWorker(QObject):
    finished = pyqtSignal(str)
    error = pyqtSignal(str)

    def __init__(self, design_code, api_key=None, api_url=None):
        super().__init__()
        self.design_code = design_code
        self.api_key = api_key
        self.api_url = api_url

    def run(self):
        # If API key and URL are provided, try calling the API (simple POST contract)
        if self.api_key and self.api_url:
            try:
                import requests
                prompt = f"Generate a complete Verilog testbench for the following design:\n\n{self.design_code}"
                headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
                payload = {"prompt": prompt, "max_tokens": 1200}
                resp = requests.post(self.api_url, json=payload, headers=headers, timeout=30)
                if resp.status_code == 200:
                    # Assume response JSON has a 'text' field
                    data = resp.json()
                    tb = data.get('text') or data.get('generated_text') or str(data)
                    self.finished.emit(tb)
                else:
                    self.error.emit(f"AI API error: {resp.status_code} {resp.text}")
            except Exception as e:
                self.error.emit(f"AI API call failed: {e}")
        else:
            # Fallback: local heuristic generator
            try:
                m = re.search(r"module\s+(\w+)", self.design_code)
                mod = m.group(1) if m else 'top'
                tb = f"// Generated local testbench for module {mod}\n" \
                     f"module tb_{mod};\n" \
                     "  // TODO: wire/reg declarations\n" \
                     "  initial begin\n" \
                     "    $dumpfile(\"dump.vcd\");\n" \
                     "    $dumpvars(0, tb_{mod});\n" \
                     "    $display(\"Simulation started\");\n" \
                     "    #100 $finish;\n" \
                     "  end\n" \
                     "endmodule\n"
                self.finished.emit(tb)
            except Exception as e:
                self.error.emit(str(e))


class SettingsDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Settings')
        self.layout = QVBoxLayout()
        self.setLayout(self.layout)
        from PyQt6.QtWidgets import QComboBox
        # Provider selection
        self.provider_label = QLabel('AI Provider:')
        self.provider_combo = QComboBox()
        self.provider_combo.addItems(['generic', 'openai'])

        # API settings
        self.api_key_label = QLabel('AI API Key:')
        self.api_key_input = QLineEdit()
        self.api_url_label = QLabel('AI API URL (POST endpoint):')
        self.api_url_input = QLineEdit()

        # Optional model input for OpenAI
        self.model_label = QLabel('Model (for OpenAI):')
        self.model_input = QLineEdit()
        self.model_input.setPlaceholderText('gpt-4o-mini (optional)')

        # Assemble
        self.layout.addWidget(self.provider_label)
        self.layout.addWidget(self.provider_combo)
        self.layout.addWidget(self.api_key_label)
        self.layout.addWidget(self.api_key_input)
        self.layout.addWidget(self.api_url_label)
        self.layout.addWidget(self.api_url_input)
        self.layout.addWidget(self.model_label)
        self.layout.addWidget(self.model_input)

        buttons = QHBoxLayout()
        self.save_btn = QPushButton('Save')
        self.cancel_btn = QPushButton('Cancel')
        buttons.addWidget(self.save_btn)
        buttons.addWidget(self.cancel_btn)
        self.layout.addLayout(buttons)

        self.save_btn.clicked.connect(self.accept)
        self.cancel_btn.clicked.connect(self.reject)

        s = load_settings()
        self.provider_combo.setCurrentText(s.get('provider','generic'))
        self.api_key_input.setText(s.get('api_key',''))
        self.api_url_input.setText(s.get('api_url',''))
        self.model_input.setText(s.get('model',''))

    def get_values(self):
        return {
            'provider': self.provider_combo.currentText(),
            'api_key': self.api_key_input.text().strip(),
            'api_url': self.api_url_input.text().strip(),
            'model': self.model_input.text().strip()
        }


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('VeriSimple IDE')
        # Adapt initial window size to available screen geometry (90% width, 85% height)
        try:
            screen = QApplication.primaryScreen()
            if screen is not None:
                rect = screen.availableGeometry()
                w = max(800, int(rect.width() * 0.9))
                h = max(600, int(rect.height() * 0.85))
                self.resize(w, h)
                # center
                self.move(rect.left() + (rect.width() - w) // 2, rect.top() + (rect.height() - h) // 2)
            else:
                self.resize(1000, 700)
        except Exception:
            self.resize(1000, 700)

        self.design_path = None
        self.tb_path = None

        # Central widget and layout
        central = QWidget()
        self.vlayout = QVBoxLayout(central)
        self.vlayout.setContentsMargins(4,4,4,4)
        self.setCentralWidget(central)

        # Toolbar
        self.toolbar = QToolBar('Main')
        self.addToolBar(self.toolbar)

        run_icon = QIcon(str(APP_DIR / 'icons' / 'run.svg')) if (APP_DIR / 'icons' / 'run.svg').exists() else QIcon()
        wave_icon = QIcon(str(APP_DIR / 'icons' / 'wave.svg')) if (APP_DIR / 'icons' / 'wave.svg').exists() else QIcon()
        ai_icon = QIcon(str(APP_DIR / 'icons' / 'ai.svg')) if (APP_DIR / 'icons' / 'ai.svg').exists() else QIcon()

        run_action = QAction(run_icon, 'Run Simulation', self)
        run_action.setShortcut(QKeySequence('Ctrl+R'))
        run_action.triggered.connect(self.on_run_sim)
        self.toolbar.addAction(run_action)

        wave_action = QAction(wave_icon, 'Show Waveform', self)
        wave_action.setShortcut(QKeySequence('Ctrl+W'))
        wave_action.triggered.connect(self.on_show_wave)
        self.toolbar.addAction(wave_action)

        ai_action = QAction(ai_icon, 'AI Generate TB', self)
        ai_action.setShortcut(QKeySequence('Ctrl+G'))
        ai_action.triggered.connect(self.on_ai_generate)
        self.toolbar.addAction(ai_action)

        settings_icon = QIcon()  # placeholder
        settings_action = QAction(settings_icon, 'Settings', self)
        settings_action.setShortcut(QKeySequence('Ctrl+,'))
        settings_action.triggered.connect(self.on_settings)
        self.toolbar.addAction(settings_action)

        # Splitter with two editors
        self.splitter = QSplitter(Qt.Orientation.Horizontal)
        self.design_editor = CodeEditor()
        self.design_editor.setObjectName('editor')
        self.design_editor.setPlaceholderText('Design (Verilog)')
        self.design_highlighter = VerilogHighlighter(self.design_editor.document())
        self.tb_editor = CodeEditor()
        self.tb_editor.setObjectName('editor')
        self.tb_editor.setPlaceholderText('Testbench (Verilog)')
        self.tb_highlighter = VerilogHighlighter(self.tb_editor.document())
        self.splitter.addWidget(self.design_editor)
        self.splitter.addWidget(self.tb_editor)
        self.splitter.setStretchFactor(0,1)
        self.splitter.setStretchFactor(1,1)

        # Console at bottom
        self.console = QTextEdit()
        self.console.setObjectName('console')
        self.console.setReadOnly(True)
        self.console.setFixedHeight(180)

        self.vlayout.addWidget(self.splitter)
        self.vlayout.addWidget(self.console)

        # Menu bar
        menubar = self.menuBar()
        file_menu = menubar.addMenu('File')
        # Open
        open_design = QAction('Open Design', self)
        open_design.triggered.connect(lambda: self.open_file(design=True))
        open_tb = QAction('Open Testbench', self)
        open_tb.triggered.connect(lambda: self.open_file(design=False))
        file_menu.addAction(open_design)
        file_menu.addAction(open_tb)
        # Save
        save_design = QAction('Save Design', self)
        save_design.triggered.connect(lambda: self.save_file(design=True, save_as=False))
        save_tb = QAction('Save Testbench', self)
        save_tb.triggered.connect(lambda: self.save_file(design=False, save_as=False))
        file_menu.addAction(save_design)
        file_menu.addAction(save_tb)
        # Save As
        saveas_design = QAction('Save As Design', self)
        saveas_design.triggered.connect(lambda: self.save_file(design=True, save_as=True))
        saveas_tb = QAction('Save As Testbench', self)
        saveas_tb.triggered.connect(lambda: self.save_file(design=False, save_as=True))
        file_menu.addAction(saveas_design)
        file_menu.addAction(saveas_tb)

        self.status = QStatusBar()
        self.setStatusBar(self.status)

        # Apply style if present
        qss_path = APP_DIR / 'style.qss'
        if qss_path.exists():
            try:
                with open(qss_path, 'r', encoding='utf-8') as f:
                    self.setStyleSheet(f.read())
            except Exception:
                pass

        # Thread placeholders
        self.ai_thread = None
        self.ai_worker = None

    # File handling
    def open_file(self, design=True):
        caption = 'Open Design' if design else 'Open Testbench'
        filt = 'Verilog files (*.v *.sv);;All files (*)'
        path, _ = QFileDialog.getOpenFileName(self, caption, str(APP_DIR), filt)
        if path:
            try:
                txt = Path(path).read_text(encoding='utf-8')
                if design:
                    self.design_editor.setPlainText(txt)
                    self.design_path = path
                else:
                    self.tb_editor.setPlainText(txt)
                    self.tb_path = path
                self.log(f'Opened: {path}')
            except Exception as e:
                QMessageBox.critical(self, 'Error', f'Failed to open file: {e}')

    def save_file(self, design=True, save_as=False):
        if design:
            editor = self.design_editor
            current = self.design_path
            caption = 'Save Design As' if save_as else 'Save Design'
        else:
            editor = self.tb_editor
            current = self.tb_path
            caption = 'Save Testbench As' if save_as else 'Save Testbench'

        if not current or save_as:
            path, _ = QFileDialog.getSaveFileName(self, caption, str(APP_DIR), 'Verilog files (*.v *.sv);;All files (*)')
            if not path:
                return False
            if design:
                self.design_path = path
            else:
                self.tb_path = path
            current = path
        try:
            Path(current).write_text(editor.toPlainText(), encoding='utf-8')
            self.log(f'Saved: {current}')
            return True
        except Exception as e:
            QMessageBox.critical(self, 'Error', f'Failed to save file: {e}')
            return False

    def saveAllFiles(self):
        ok1 = True
        ok2 = True
        if self.design_path:
            ok1 = self.save_file(design=True, save_as=False)
        else:
            # for unsaved design, ask Save As
            ok1 = self.save_file(design=True, save_as=True)
        if self.tb_path:
            ok2 = self.save_file(design=False, save_as=False)
        else:
            ok2 = self.save_file(design=False, save_as=True)
        return ok1 and ok2

    def log(self, txt):
        self.console.append(txt)

    # Simulation integration
    def on_run_sim(self):
        self.console.clear()
        self.log('Starting simulation...')
        if not self.saveAllFiles():
            self.log('Save cancelled. Aborting.')
            return
        if not self.design_path or not self.tb_path:
            self.log('Both design and testbench files must be set.')
            return
        compiled = APP_DIR / 'compiled_sim.o'
        cmd = ['iverilog', '-o', str(compiled), str(self.design_path), str(self.tb_path)]
        self.log('Running: ' + ' '.join(cmd))
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if proc.stdout:
                self.log(proc.stdout)
            if proc.stderr:
                self.log('Compiler stderr:\n' + proc.stderr)
            if proc.returncode != 0:
                self.log(f'Compilation failed with code {proc.returncode}')
                return
        except FileNotFoundError:
            self.log('Error: iverilog not found. Make sure Icarus Verilog is installed and in PATH.')
            return
        except Exception as e:
            self.log(f'Compilation exception: {e}')
            return

        # Run vvp
        run_cmd = ['vvp', str(compiled)]
        self.log('Running: ' + ' '.join(run_cmd))
        try:
            proc2 = subprocess.run(run_cmd, capture_output=True, text=True, check=False)
            if proc2.stdout:
                self.log(proc2.stdout)
            if proc2.stderr:
                self.log('Simulator stderr:\n' + proc2.stderr)
        except FileNotFoundError:
            self.log('Error: vvp not found. Make sure Icarus Verilog is installed and in PATH.')
            return
        except Exception as e:
            self.log(f'Simulation exception: {e}')
            return

        self.log('Simulation finished.')

    def on_show_wave(self):
        # Try to find dump.vcd next to testbench or in current dir
        if not self.tb_path:
            self.log('Please open or save a testbench first.')
            return
        tbdir = Path(self.tb_path).parent
        candidates = [tbdir / 'dump.vcd', APP_DIR / 'dump.vcd']
        found = None
        for c in candidates:
            if c.exists():
                found = c
                break
        if not found:
            self.log('No dump.vcd found. Please run a simulation first or ensure your testbench writes dump.vcd')
            return
        # Launch gtkwave detached
        try:
            if os.name == 'nt':
                DETACHED = subprocess.CREATE_NEW_CONSOLE
                subprocess.Popen(['gtkwave', str(found)], creationflags=DETACHED)
            else:
                subprocess.Popen(['gtkwave', str(found)])
            self.log(f'Launched GTKWave for {found}')
        except FileNotFoundError:
            self.log('Error: gtkwave not found. Make sure GTKWave is installed and in PATH.')
        except Exception as e:
            self.log(f'Failed to launch gtkwave: {e}')

    # AI TB generation
    def on_ai_generate(self):
        design_code = self.design_editor.toPlainText()
        if not design_code.strip():
            self.log('Design editor is empty. Cannot generate testbench.')
            return
        s = load_settings()
        api_key = s.get('api_key')
        api_url = s.get('api_url')

        # Run worker in QThread
        self.log('Starting AI testbench generation...')
        self.ai_thread = QThread()
        self.ai_worker = AIWorker(design_code, api_key=api_key, api_url=api_url)
        self.ai_worker.moveToThread(self.ai_thread)
        self.ai_thread.started.connect(self.ai_worker.run)
        self.ai_worker.finished.connect(self.on_ai_finished)
        self.ai_worker.error.connect(self.on_ai_error)
        self.ai_worker.finished.connect(self.ai_thread.quit)
        self.ai_worker.finished.connect(self.ai_worker.deleteLater)
        self.ai_thread.finished.connect(self.ai_thread.deleteLater)
        self.ai_thread.start()

    def on_ai_finished(self, tb_text):
        self.tb_editor.setPlainText(tb_text)
        self.log('AI generation finished and testbench populated.')

    def on_ai_error(self, err):
        self.log('AI generation error: ' + err)

    def on_settings(self):
        dlg = SettingsDialog(self)
        if dlg.exec():
            vals = dlg.get_values()
            s = load_settings()
            s.update(vals)
            save_settings(s)
            self.log('Settings saved.')


def main():
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == '__main__':
    main()
