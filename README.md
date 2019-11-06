# ShareExt-iOS
Share Extension for iOS.

Share URL to your app using share extension feature. 

# Steps for running share extension in your xcode project.  

1. first you have to add share extention by clicking on the plus button in xcode project (in Project & Targets tab). 
2. Create an App group. Make sure your share extension and your main app has the same app group selected. 
3. Add Action.js file in your share extension folder.
4. Now Replace your shareViewController. 
5. Inside your info.plist you have to replace this code. 
    
    ```<key>NSExtensionJavaScriptPreprocessingFile</key>
         <string>Action</string>
         <key>NSExtensionActivationRule</key>
         <dict>
            <key>NSExtensionActivationSupportsText</key>
            <true/>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
         </dict>
      </dict>```
      
That's it! 
