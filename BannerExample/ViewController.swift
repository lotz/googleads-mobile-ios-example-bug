//
//  Copyright 2023 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import GoogleMobileAds
import UIKit
import WebKit

class ViewController: UIViewController, GADBannerViewDelegate {
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var privacySettingsButton: UIBarButtonItem!
    @IBOutlet weak var bannerWebViewURLStatus: UILabel!
    
    private var didBecomeActiveNotification: NSObjectProtocol?
    
    private var isMobileAdsStartCalled = false
    private var isViewDidAppearCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Replace this ad unit ID with your own ad unit ID.
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2435281174"
        bannerView.rootViewController = self
        bannerView.delegate = self
        
        GoogleMobileAdsConsentManager.shared.gatherConsent(from: self) { [weak self] (consentError) in
            guard let self else { return }
            
            if let consentError {
                // Consent gathering failed.
                print("Error: \(consentError.localizedDescription)")
            }
            
            if GoogleMobileAdsConsentManager.shared.canRequestAds {
                self.startGoogleMobileAdsSDK()
            }
            
            self.privacySettingsButton.isEnabled =
            GoogleMobileAdsConsentManager.shared.isPrivacyOptionsRequired
        }
        
        // This sample attempts to load ads using consent obtained in the previous session.
        if GoogleMobileAdsConsentManager.shared.canRequestAds {
            startGoogleMobileAdsSDK()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Attempting to load adaptive banner ads is handled in viewDidAppear as this is the first
        // time that the safe area is known. If safe area is not a concern (eg your app is locked
        // in portrait mode) the banner can be loaded in viewDidLoad.
        if GoogleMobileAdsConsentManager.shared.canRequestAds {
            loadBannerAd()
        }
        isViewDidAppearCalled = true
        
        // Update and show a status of the URL of the WKWebView in the view hierarchy
        updateBannerWebViewURLStatus()
        
        didBecomeActiveNotification = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let self = self else { return }
            
            self.updateBannerWebViewURLStatus()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let didBecomeActiveNotification = didBecomeActiveNotification else { return }
        
        NotificationCenter.default.removeObserver(didBecomeActiveNotification)
    }
    
    private func updateBannerWebViewURLStatus() {
        var statusText: String
        
        if let webView = view.findFirstSubview(ofType: WKWebView.self) {
            if webView.url != nil {
                statusText = "Not nil\n\n✅"
            } else {
                statusText = "Nil!\n\n🚨"
            }
        } else {
            statusText = "WKWebView not found...\n\n🔍"
        }
        
        bannerWebViewURLStatus.text = "WKWebView URL:\n\n\(statusText)"
    }
    
    override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        coordinator.animate(alongsideTransition: { _ in
            if GoogleMobileAdsConsentManager.shared.canRequestAds {
                self.loadBannerAd()
            }
        })
    }
    
    // Handle changes to user consent.
    @IBAction func privacySettingsTapped(_ sender: UIBarButtonItem) {
        GoogleMobileAdsConsentManager.shared.presentPrivacyOptionsForm(from: self) {
            [weak self] (formError) in
            guard let self, let formError else { return }
            
            let alertController = UIAlertController(
                title: formError.localizedDescription, message: "Please try again later.",
                preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alertController, animated: true)
        }
    }
    
    private func startGoogleMobileAdsSDK() {
        DispatchQueue.main.async {
            guard !self.isMobileAdsStartCalled else { return }
            
            self.isMobileAdsStartCalled = true
            
            // Initialize the Google Mobile Ads SDK.
            GADMobileAds.sharedInstance().start()
            
            if self.isViewDidAppearCalled {
                self.loadBannerAd()
            }
        }
    }
    
    func loadBannerAd() {
        let viewWidth = view.frame.inset(by: view.safeAreaInsets).width
        
        // Here the current interface orientation is used. Use
        // GADLandscapeAnchoredAdaptiveBannerAdSizeWithWidth or
        // GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth if you prefer to load an ad of a
        // particular orientation
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        
        bannerView.load(GADRequest())
    }
    
    // MARK: - GADBannerViewDelegate methods
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print(#function)
        
        updateBannerWebViewURLStatus()
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(#function + ": " + error.localizedDescription)
        
        updateBannerWebViewURLStatus()
    }
    
    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        print(#function)
    }
    
    func adViewDidRecordImpression(_ bannerView: GADBannerView) {
        print(#function)
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print(#function)
    }
}

extension UIView {
    func findFirstSubview<T: UIView>(ofType type: T.Type) -> T? {
        for subview in subviews {
            if let typedSubview = subview as? T {
                return typedSubview
            }
            if let foundSubview = subview.findFirstSubview(ofType: type) {
                return foundSubview
            }
        }
        return nil
    }
}
