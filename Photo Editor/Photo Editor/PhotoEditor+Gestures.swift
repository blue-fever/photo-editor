//
//  PhotoEditor+Gestures.swift
//  Photo Editor
//
//  Created by Mohamed Hamed on 6/16/17.
//
//

import Foundation
import KMPlaceholderTextView
import UIKit

extension PhotoEditorViewController : UIGestureRecognizerDelegate  {
    
    /**
     UIPanGestureRecognizer - Moving Objects
     */
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        if (isTyping) {
            return
        }
        
        if let view = recognizer.view {
            if view is UIImageView {
                if recognizer.state == .began {
                    if let view = recognizer.view {
                        if canvasImageView.subviews.contains(view) {
                            imageViewToPan = (view as! UIImageView)
                        }
                    }
                }
                if imageViewToPan != nil {
                    moveView(view: imageViewToPan!, recognizer: recognizer)
                }
            } else {
                moveView(view: view, recognizer: recognizer)
            }
        }
    }
    
    /**
     UIPinchGestureRecognizer - Pinching Objects
     If it's a UITextView will make the font bigger so it doen't look pixlated
     */
    @objc func pinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        // For V1 only gifs and stickers can be scaled
        
        if let view = recognizer.view {
            if view.subviews.count == 1 && view.subviews[0] is KMPlaceholderTextView {
                let textView = view.subviews[0] as! KMPlaceholderTextView
                
                if textView.font!.pointSize * recognizer.scale > 10 && textView.font!.pointSize * recognizer.scale < 50 {
                    let font = UIFont(name: textView.font!.fontName, size: textView.font!.pointSize * recognizer.scale)
                    textView.font = font
                    let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width - 40,
                                                                 height:CGFloat.greatestFiniteMagnitude))
                    textView.bounds.size = CGSize(width: UIScreen.main.bounds.size.width - 40,
                                                  height: sizeToFit.height)
                } else {
                    let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width - 40,
                                                                 height:CGFloat.greatestFiniteMagnitude))
                    textView.bounds.size = CGSize(width: UIScreen.main.bounds.size.width - 40,
                                                  height: sizeToFit.height)
                }
                
                
                textView.setNeedsDisplay()
            } else {
                let transform:CGAffineTransform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
                
                if (scale(from: view.transform) < 10 || scale(from: view.transform) > scale(from: transform)) {
                    view.transform = transform
                }
            }
            recognizer.scale = 1
            
        }
    }
    
    /**
     UIRotationGestureRecognizer - Rotating Objects
     */
    @objc func rotationGesture(_ recognizer: UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    
    /**
     UITapGestureRecognizer - Taping on Objects
     Will make scale scale Effect
     */
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if (isTyping) {
            closeTextTool()
            return
        }
        
        if let view = recognizer.view {
            if view is UIImageView {
                if let view = recognizer.view {
                    if canvasImageView.subviews.contains(view) {
                        scaleEffect(view: view)
                        
                    }
                }
            } else {
                canvasImageView.bringSubviewToFront(view)
            }
        }
    }
    
    /*
     Support Multiple Gesture at the same time
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            if !gifsStickersVCIsVisible {
                addGifsStickersViewController()
            }
        }
    }
    
    // to Override Control Center screen edge pan from bottom
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    /**
     Scale Effect
     */
    func scaleEffect(view: UIView) {
        view.superview?.bringSubviewToFront(view)
        
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        let previouTransform =  view.transform
        UIView.animate(withDuration: 0.2,
                       animations: {
                        view.transform = view.transform.scaledBy(x: 1.2, y: 1.2)
                       },
                       completion: { _ in
                        UIView.animate(withDuration: 0.2) {
                            view.transform  = previouTransform
                        }
                       })
    }
    
    /**
     Moving Objects 
     delete the view if it's inside the delete view
     Snap the view back if it's out of the canvas
     */
    
    func moveView(view: UIView, recognizer: UIPanGestureRecognizer)  {
        hideToolbar(hide: true)
        deleteView.isHidden = false
        
        view.superview?.bringSubviewToFront(view)
        let pointToSuperView = recognizer.location(in: self.view)
        view.center = CGPoint(x: view.center.x + recognizer.translation(in: canvasImageView).x,
                              y: view.center.y + recognizer.translation(in: canvasImageView).y)
        let center = self.view.convert(view.center, from: canvasImageView)
        
        if (view.center.x > UIScreen.main.bounds.width / 2 - 5 && view.center.x < UIScreen.main.bounds.width / 2 + 5) {
            view.center = CGPoint(x: canvasImageView.frame.width / 2,
                                  y: view.center.y + recognizer.translation(in: canvasImageView).y)
            centerHorizontalView.isHidden = false
        } else {
            centerHorizontalView.isHidden = true
        }
        
        if (center.y > UIScreen.main.bounds.size.height / 2 - 5 && center.y < UIScreen.main.bounds.size.height / 2 + 5) {
            view.center = CGPoint(x: view.center.x + recognizer.translation(in: canvasImageView).x,
                                  y: canvasImageView.frame.height / 2)
            centerVerticalView.isHidden = false
        } else {
            centerVerticalView.isHidden = true
        }
        
        recognizer.setTranslation(CGPoint.zero, in: canvasImageView)
        
        if let previousPoint = lastPanPoint {
            //View is going into deleteView
            if deleteView.frame.contains(pointToSuperView) && !deleteView.frame.contains(previousPoint) {
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                }
                UIView.animate(withDuration: 0.3, animations: {
                    view.transform = view.transform.scaledBy(x: 0.25, y: 0.25)
                    view.center = recognizer.location(in: self.canvasImageView)
                })
            }
            //View is going out of deleteView
            else if deleteView.frame.contains(previousPoint) && !deleteView.frame.contains(pointToSuperView) {
                //Scale to original Size
                UIView.animate(withDuration: 0.3, animations: {
                    view.transform = view.transform.scaledBy(x: 4, y: 4)
                    view.center = recognizer.location(in: self.canvasImageView)
                })
            }
        }
        lastPanPoint = pointToSuperView
        
        if recognizer.state == .ended {
            centerHorizontalView.isHidden = true
            centerVerticalView.isHidden = true
            imageViewToPan = nil
            lastPanPoint = nil
            hideToolbar(hide: false)
            deleteView.isHidden = true
            let point = recognizer.location(in: self.view)
            
            if deleteView.frame.contains(point) { // Delete the view
                view.removeFromSuperview()
                
                clearAfterRemove(view: view)
                
                if #available(iOS 10.0, *) {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } else if !canvasImageView.bounds.contains(view.center) { //Snap the view back to canvasImageView
                UIView.animate(withDuration: 0.3, animations: {
                    view.center = self.canvasImageView.center
                })
                
            }
        }
    }
    
    func clearAfterRemove (view: UIView) {
        if (view is UITextView) {
            activeTextView = nil
            textColor = UIColor.black
            colorsCollectionView.reloadData()
            textSizeSlider.value = 20
            setFontStyleButton(fontIndex: 0)
            setAlignButton(align: .left)
        }
        
        if let imageView = view as? UIImageView {
            if(gifsImages.contains(imageView)) {
                gifsSources.remove(at: gifsImages.index(of: imageView)!)
                gifsImages.remove(at: gifsImages.index(of: imageView)!)
            }
        }
    }
    
    func subImageViews(view: UIView) -> [UIImageView] {
        var imageviews: [UIImageView] = []
        for imageView in view.subviews {
            if imageView is UIImageView {
                imageviews.append(imageView as! UIImageView)
            }
        }
        return imageviews
    }
    
    func scale(from transform: CGAffineTransform) -> Double {
        return sqrt(Double(transform.a * transform.a + transform.c * transform.c))
    }
}
