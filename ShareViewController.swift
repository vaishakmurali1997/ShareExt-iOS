//
//  ShareViewController.swift
//  Created by Vaishak Murali on 06/11/19.
//

import UIKit
import Social
import MobileCoreServices

@available(iOSApplicationExtension 8.0, *)
class ShareViewController: SLComposeServiceViewController {
    
    let contentTypeList = kUTTypePropertyList as String
    let contentTypeTitle = "public.plain-text"
    let contentTypeUrl = "public.url"
    
    // We don't want to show the view actually
    // as we directly open our app!
    override func viewWillAppear(_ animated: Bool) {
        self.view.isHidden = true
        self.cancel()
        self.doClipping()
    }
    
    // We directly forward all the values retrieved from Action.js to our app
    private func doClipping() {
        self.loadJsExtensionValues { dict in
            let url = "your_custom_url_scheme" + self.dictionaryToQueryString(dict: dict)
            self.doOpenUrl(url: url)
        }
    }
    
    private func dictionaryToQueryString(dict: Dictionary<String,String>) -> String {
        return dict.map({ entry in
            let value = entry.1
            let valueEncoded = value.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
            return entry.0 + "=" + valueEncoded!
        }).joined(separator: "&")
    }
    
    // See https://github.com/extendedmind/extendedmind/blob/master/frontend/cordova/app/platforms/ios/extmd-share/ShareViewController.swift
    private func loadJsExtensionValues(f: @escaping (Dictionary<String,String>) -> Void) {
        let content = extensionContext!.inputItems[0] as! NSExtensionItem
        if (self.hasAttachmentOfType(content: content, contentType: contentTypeList)) {
            self.loadJsDictionnary(content: content) { dict in
                f(dict)
            }
        } else {
            self.loadUTIDictionnary(content: content) { dict in
                // 2 Items should be in dict to launch clipper opening : url and title.
                if (dict.count==2) { f(dict) }
            }
        }
    }
    
    private func hasAttachmentOfType(content: NSExtensionItem,contentType: String) -> Bool {
        for attachment in content.attachments as! [NSItemProvider] {
            if attachment.hasItemConformingToTypeIdentifier(contentType) {
                return true;
            }
        }
        return false;
    }
    
    private func loadJsDictionnary(content: NSExtensionItem,f: @escaping (Dictionary<String,String>) -> Void)  {
        for attachment in content.attachments as! [NSItemProvider] {
            if attachment.hasItemConformingToTypeIdentifier(contentTypeList) {
                attachment.loadItem(forTypeIdentifier: contentTypeList, options: nil) { data, error in
                    if ( error == nil && data != nil ) {
                        let jsDict = data as! NSDictionary
                        if let jsPreprocessingResults = jsDict[NSExtensionJavaScriptPreprocessingResultsKey] {
                            let values = jsPreprocessingResults as! Dictionary<String,String>
                            f(values)
                        }
                    }
                }
            }
        }
    }
    
    
    private func loadUTIDictionnary(content: NSExtensionItem,f: @escaping (Dictionary<String,String>) -> Void) {
        var dict = Dictionary<String, String>()
        loadUTIString(content: content, utiKey: contentTypeUrl   , handler: { url_NSSecureCoding in
            let url_NSurl = url_NSSecureCoding as! NSURL
            let url_String = url_NSurl.absoluteString as! String
            dict["url"] = url_String
            f(dict)
        })
        loadUTIString(content: content, utiKey: contentTypeTitle, handler: { title_NSSecureCoding in
            let title = title_NSSecureCoding as! String
            dict["title"] = title
            f(dict)
        })
    }
    
    
    private func loadUTIString(content: NSExtensionItem,utiKey: String,handler: @escaping  (NSSecureCoding) -> Void) {
        for attachment in content.attachments as! [NSItemProvider] {
            if attachment.hasItemConformingToTypeIdentifier(utiKey) {
                attachment.loadItem(forTypeIdentifier: utiKey, options: nil, completionHandler: { (data, error) -> Void in
                    if ( error == nil && data != nil ) {
                        handler(data!)
                    }
                })
            }
        }
    }
    
    
    private func doOpenUrl(url: String) {
        let urlNS = NSURL(string: url)!
        var responder = self as UIResponder?
        while (responder != nil){
            if responder!.responds(to: Selector("openURL:"))  == true{
                responder!.callSelector(selector: Selector("openURL:"), object: urlNS, delay: 0)
            }
            responder = responder!.next
        }
    }
}

extension NSObject {
    func callSelector(selector: Selector, object: AnyObject?, delay: TimeInterval) {
        let delay = delay * Double(NSEC_PER_SEC)
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: {
            Thread.detachNewThreadSelector(selector, toTarget:self, with: object)
        })
    }
}
