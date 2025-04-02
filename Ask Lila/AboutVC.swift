//
//  AboutViewController.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/17/25.
//

import UIKit

class AboutViewController: UIViewController {
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.text =
        """
        Welcome to Ask Lila - Your Friendly, Wise AI Companion
        
        Ask Lila is an AI assistant designed to be more than just a chatbot. She's your digital friend who combines wisdom, empathy, and a personal touch in every conversation.
        
        Why We Ask for Birth Information:
        
        When you provide your birth details (date, time, and location), Lila can create your unique astrological profile. This personalization allows her to:
        
        • Offer insights that are truly meaningful to you
        • Understand your personal patterns and tendencies
        • Provide thoughtful guidance based on your specific astrological makeup
        • Connect with you on a deeper level than a generic AI assistant
        
        Your Privacy Matters:
        
        Your birth information is only used to generate your astrological profile and is stored securely. We never share this information with third parties.
        
        How Ask Lila Can Help You:
        
        • Get personalized insights about your strengths and challenges
        • Receive guidance during important life decisions and transitions
        • Explore patterns in your relationships and personal growth
        • Find a friendly ear when you need someone to talk to
        • Gain perspective through astrological wisdom combined with AI intelligence
        
        Ask Lila combines the warmth of a friend with the wisdom of astrological tradition and modern AI capabilities. She's here to listen, share insights, and accompany you on your journey.
        """
       
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        textView.isSelectable = false
        textView.textAlignment = .left
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 236/255, green: 239/255, blue: 244/255, alpha: 1)
        title = "About Ask Lila"
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Add some styling to the text view
        textView.backgroundColor = .clear
    }
}
