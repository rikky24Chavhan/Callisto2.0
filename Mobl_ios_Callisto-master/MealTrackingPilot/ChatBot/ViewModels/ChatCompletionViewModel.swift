//
//  ChatCompletionViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/1/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

class ChatCompletionViewModel {
    private var completion: (() -> Void)?
    private var messageText: String = "We’re all set! Let’s get started with a Demo of our app."

    func typingViewModel() -> ChatMessageViewModel {
        return messageViewModelForAnimationState(.typing)
    }

    func slidingViewModel() -> ChatMessageViewModel {
        return messageViewModelForAnimationState(.sliding)
    }

    func expandingViewModel() -> ChatMessageViewModel {
        return messageViewModelForAnimationState(.expanding)
    }

    private func messageViewModelForAnimationState(_ state: ChatMessageAnimationState) -> ChatMessageViewModel {
        let message = Message(text: self.messageText, textStyle: .bold, sender: .guru)
        return ChatMessageViewModel(message: message, animationState: state, isHighlighted: false)
    }

    init(completion: (() -> Void)? = nil) {
        self.completion = completion
    }

    func didPressContinue() {
        completion?()
    }
}
