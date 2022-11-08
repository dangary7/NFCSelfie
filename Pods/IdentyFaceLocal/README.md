IDENTY Face Local SDK

#Installation

   The IDENTY Face Local SDK  is compatible with Apple iOS version 10.0 and above.
        IDENTY Face Local SDK is available through CocoaPods.
⁃    Install cocoapods  

        $ sudo gem install cocoapods   
⁃    Create Pod file inside project workspace
   
        $ pod init
⁃    To install sdk, simply add the following to your Podfile:
    
        # Uncomment the next line to define a global platform for your project
        # platform :ios, '11.0'
        plugin 'cocoapods-art', :sources => [
         'cocoapods-local-face'
        ]
        target 'IdentyProject' do
        #use_frameworks!
        pod 'IdentyFaceLocal','3.0.1.0'
        end

⁃    You will need to access cocoa pods private repo to get started.

#Cocoapods

1.    Set your repository credentials. The first step is to add the credentials received from Identy into  your .netrc file. Navigate to your home folder and create a file called .netrc

          cd ~/
          vi .netrc

       Add the credentials in the following format:

          machine identy.jfrog.io
          login ${provided_username}
          password ${provided_encrypted_password}

2. Install cocoapods-art

        $ sudo gem install cocoapods-art 

3. Add repository to the local

        $ pod repo-art add cocoapods-local-face "https://identy.jfrog.io/identy/api/pods/cocoapods-local-face"

4. Update the pod repo in need  to use the updated SDK version.

         $ pod repo-art update cocoapods-local-face 
         $ pod install
  
#Set Enable Bitcode to NO in Build settings.

#Usage

    var faceMatch : FaceMatcher!
    let instat = FaceLocalMatch()
    faceMatch = FaceLocalMatcher(instat.getLocalMatcher())
    


