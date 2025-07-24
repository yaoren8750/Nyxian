//
//  CodeEditor.swift
//  LindDE
//
//  Created by lindsey on 05.05.25.
//

import UIKit
import Runestone
import TreeSitter
import TreeSitterC
import TreeSitterObjc
import TreeSitterXML

// MARK: - OnDissapear Container
class OnDisappearUIView: UIView {
    var onDisappear: () -> Void = {}

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            onDisappear()
        }
    }
}

class CodeEditorViewController: UIViewController {
    private(set) var path: String
    private(set) var textView: TextView
    private(set) var project: AppProject?
    private(set) var synpushServer: SynpushServer?
    private(set) var coordinator: Coordinator?
    private(set) var database: DebugDatabase?
    private(set) var line: UInt64?
    private(set) var column: UInt64?
    
    init(
        project: AppProject?,
        path: String,
        line: UInt64? = nil,
        column: UInt64? = nil
    ) {
        self.path = path
        
        self.textView = TextView()
        
        self.project = project
        self.project?.codeEditorConfig.reloadIfNeeded()
        self.line = line
        self.column = column
        
        let cachePath = self.project!.getCachePath()
        
        self.database = DebugDatabase.getDatabase(ofPath: "\(cachePath)/debug.json")
        
        if let project = project {
            let suffix = self.path.URLGet().pathExtension
            if suffix == "c" || suffix == "m" || suffix == "cpp" || suffix == "mm" || suffix == "h" {
                var genericCompilerFlags: [String] = [
                    "-isysroot",
                    Bootstrap.shared.bootstrapPath("/SDK/iPhoneOS16.5.sdk"),
                    "-I\(Bootstrap.shared.bootstrapPath("/Include/include"))"
                ]
                
                // TODO: Analyse the includations of the .m files in the project to generate the right kinds fo flags, one example: u wrote c++ code and make a c++ header but then objective-c typechecking shouldnt happen! or the file is not included in the first place by any .m file then it shall be ignored and not typechecked
                if suffix == "h" {
                    genericCompilerFlags.append(contentsOf: [
                        "-x",
                        "objective-c",
                    ])
                }
                
                project.projectConfig.reloadIfNeeded()
                genericCompilerFlags.append(contentsOf: project.projectConfig.getCompilerFlags())
                
                self.synpushServer = SynpushServer(self.path, args: genericCompilerFlags)
            }
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view = OnDisappearUIView()
        
        do {
            self.textView.text = try String(contentsOf: URL(fileURLWithPath: self.path), encoding: .utf8)
        } catch {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // Handle it
            } else {
                self.dismiss(animated: true)
            }
        }
        
        let fileURL = URL(fileURLWithPath: self.path)
        self.title = fileURL.lastPathComponent
        
        let saveButton: UIBarButtonItem = UIBarButtonItem()
        saveButton.tintColor = .label
        saveButton.title = "Save"
        saveButton.target = self
        saveButton.action = #selector(saveText)
        self.navigationItem.setRightBarButton(saveButton, animated: true)
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            let closeButton: UIBarButtonItem = UIBarButtonItem()
            closeButton.tintColor = .label
            closeButton.title = "Close"
            closeButton.target = self
            closeButton.action = #selector(closeEditor)
            self.navigationItem.setLeftBarButton(closeButton, animated: true)
        }
        
        if let theme = currentTheme {
            theme.fontSize = self.project?.codeEditorConfig.fontSize ?? 10.0
            
            self.view.backgroundColor = .systemBackground
            self.textView.backgroundColor = theme.backgroundColor
            self.textView.theme = theme
            
            self.navigationController?.navigationBar.prefersLargeTitles = false
            self.navigationController?.navigationBar.standardAppearance = currentNavigationBarAppearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = currentNavigationBarAppearance
        }
        
        self.textView.showLineNumbers = self.project?.codeEditorConfig.showLine ?? true
        self.textView.showSpaces = self.project?.codeEditorConfig.showSpaces ?? true
        self.textView.isLineWrappingEnabled = self.project?.codeEditorConfig.wrapLine ?? true
        self.textView.showLineBreaks = self.project?.codeEditorConfig.showReturn ?? true
        self.textView.lineSelectionDisplayType = .line
        
        self.textView.lineHeightMultiplier = 1.3
        self.textView.keyboardType = .asciiCapable
        self.textView.smartQuotesType = .no
        self.textView.smartDashesType = .no
        self.textView.smartInsertDeleteType = .no
        self.textView.autocorrectionType = .no
        self.textView.autocapitalizationType = .none
        self.textView.textContainerInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 0)
        
        func loadLanguage(language: UnsafePointer<TSLanguage>, highlightsURL: [URL]) {
            func combinedQuery(fromFilesAt fileURLs: [URL]) -> TreeSitterLanguage.Query? {
                let rawQuery = fileURLs.compactMap { try? String(contentsOf: $0) }.joined(separator: "\n")
                if !rawQuery.isEmpty {
                    return TreeSitterLanguage.Query(string: rawQuery)
                } else {
                    return nil
                }
            }
            
            let language = TreeSitterLanguage(language, highlightsQuery: combinedQuery(fromFilesAt: highlightsURL))
            let languageMode = TreeSitterLanguageMode(language: language)
            
            self.textView.setLanguageMode(languageMode)
        }
        
        switch fileURL.pathExtension {
        case "m","h":
            loadLanguage(language: tree_sitter_objc(), highlightsURL: [
                "\(Bundle.main.bundlePath)/TreeSitterObjc_TreeSitterObjc.bundle/queries/highlights.scm".URLGet(),
                "\(Bundle.main.bundlePath)/TreeSitterC_TreeSitterC.bundle/queries/highlights.scm".URLGet()
            ])
            break
        case "c":
            loadLanguage(language: tree_sitter_c(), highlightsURL: [
                "\(Bundle.main.bundlePath)/TreeSitterC_TreeSitterC.bundle/queries/highlights.scm".URLGet()
            ])
            break
        case "xml","plist":
            loadLanguage(language: tree_sitter_xml(), highlightsURL: [
                "\(Bundle.main.bundlePath)/TreeSitterXML_TreeSitterXML.bundle/xml/highlights.scm".URLGet()
            ])
            break
        default:
            break
        }
            
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        self.setupToolbar(textView: self.textView)
        
        self.coordinator = Coordinator(parent: self)
        self.textView.editorDelegate = self.coordinator
        
        (self.view as! OnDisappearUIView).onDisappear = { [weak self] in
            guard let synpushServer = self?.synpushServer else { return }
            synpushServer.deinit()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard var line = self.line else { return }
            guard var column = self.column else { return }
            line -= 1
            column -= 1
            
            let lines = self.textView.text.components(separatedBy: .newlines)
            guard line < lines.count else { return }

            let lineText = lines[Int(line)]
            let clampedColumn = min(Int(column), lineText.count)

            let offset = lines.prefix(Int(line)).reduce(0) { $0 + $1.count + 1 } + clampedColumn

            guard let rect = self.textView.rectForLine(Int(line)) else { return }

            let targetOffsetY = rect.origin.y - self.textView.textContainerInset.top
            let maxOffsetY = self.textView.contentSize.height - self.textView.bounds.height
            let clampedOffsetY = max(min(targetOffsetY, maxOffsetY), 0)

            let targetOffset = CGPoint(x: 0, y: clampedOffsetY)
            self.textView.setContentOffset(targetOffset, animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let start = self.textView.position(from: self.textView.beginningOfDocument, offset: offset) else { return }
                let range = self.textView.textRange(from: start, to: start)
                self.textView.selectedTextRange = range
                self.textView.becomeFirstResponder()
            }
        }
    }
    
    func setupToolbar(textView: TextView) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let theme: LindDEThemer = getCurrentSelectedTheme()
        
        if #available(iOS 15.0, *) {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground()  // Make it opaque
            appearance.backgroundColor = theme.gutterBackgroundColor
            toolbar.standardAppearance = appearance
            toolbar.scrollEdgeAppearance = appearance
        } else {
            toolbar.barTintColor = theme.gutterBackgroundColor
        }
        
        func spawnSeperator() -> UIBarButtonItem {
            return UIBarButtonItem(customView: UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 1)))
        }
        
        func getAdditionalButtons(buttons: [String]) -> [UIBarButtonItem] {
            var array: [UIBarButtonItem] = [spawnSeperator()]
            for button in buttons {
                array.append(contentsOf: [
                    UIBarButtonItem(customView: SymbolButton(symbolName: button, width: 25.0) {
                        textView.replace(textView.selectedTextRange!, withText: button)
                    }),
                    spawnSeperator()])
            }
            return array;
        }
        
        let tabBarButton = UIBarButtonItem(customView: SymbolButton(symbolName: "arrow.right.to.line", width: 35.0) {
            textView.replace(textView.selectedTextRange!, withText: "\t")
        })
        let hideBarButton = UIBarButtonItem(customView: SymbolButton(symbolName: "keyboard.chevron.compact.down", width: 35.0) {
            textView.resignFirstResponder()
        })
        
        var items: [UIBarButtonItem] = [
            tabBarButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
        

        items.append(contentsOf: getAdditionalButtons(buttons: ["(",")","{","}","[","]",";"]))
        
        items.append(contentsOf: [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            spawnSeperator(),
            hideBarButton
        ])
        
        toolbar.items = items
        textView.inputAccessoryView = toolbar
    }
    
    @objc func saveText() {
        defer {
            try? self.textView.text.write(to: URL(fileURLWithPath: self.path), atomically: true, encoding: .utf8)
        }
        
        guard let synpushServer = self.synpushServer, let coordinator = self.coordinator else { return }
        
        self.database!.setFileDebug(ofPath: self.path, synItems: self.coordinator?.diag ?? [])
        self.database!.saveDatabase(toPath: "\(self.project!.getCachePath())/debug.json")
    }
    
    @objc func closeEditor() {
        NotificationCenter.default.post(name: Notification.Name("CodeEditorDismissed"), object: nil)
        self.dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let bottomInset = keyboardFrame.height - view.safeAreaInsets.bottom
        textView.contentInset.bottom = bottomInset
        textView.scrollIndicatorInsets.bottom = bottomInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
}
