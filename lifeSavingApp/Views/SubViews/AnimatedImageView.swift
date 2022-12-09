//
//  AnimatedImageView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 16/10/2021.
//

import SwiftUI

var images : [UIImage] = [UIImage(named: "1")!,
                          UIImage(named: "2")!,
                          UIImage(named: "3")!]

let animatedImages = UIImage.animatedImage(with: images, duration: 0.5)

struct AnimatedImage: UIViewRepresentable {
    
    func makeUIView(context: Self.Context) -> UIView {
        let someView = UIView()
        let someImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        someImage.clipsToBounds = true
        someImage.autoresizesSubviews = true
        someImage.contentMode = UIView.ContentMode.scaleAspectFit
        
        someImage.image = animatedImages
        someImage.layer.cornerRadius = 20
        someImage.backgroundColor = UIColor(Color("Popup").opacity(0.95))
        DispatchQueue.main.async {
            someView.addSubview(someImage)
        }
        return someView
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<AnimatedImage>) {
        
    }
}

struct AnimatedImageView: View {
    var body: some View {
        ZStack{
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    AnimatedImage().frame(width: 100, height: 100, alignment: .center)
                    Spacer()
                }
                Spacer()
            }
        }.contentShape(Rectangle())
    }
}
