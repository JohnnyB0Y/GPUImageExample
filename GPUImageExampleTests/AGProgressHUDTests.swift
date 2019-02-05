//
//  AGProgressHUDTests.swift
//  GPUImageExampleTests
//
//  Created by JohnnyB0Y on 2019/2/4.
//  Copyright © 2019 JohnnyB0Y. All rights reserved.
//

import Quick
import Nimble

class TestAGProgressHUD: QuickSpec {
    
    override func spec() {
        
        let width: CGFloat = 320.0;
        let height: CGFloat = 44.0;
        let leading: CGFloat = 6.0;
        let trailing: CGFloat = 6.0;
        let progressHUD: AGProgressHUD = AGProgressHUD.init(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        
        describe("progressHUD property") {
            
            beforeEach {
                progressHUD.backgroundTintColor = UIColor.red
                progressHUD.trackTintColor = UIColor.orange
                
                progressHUD.progressLeading = leading;
                progressHUD.progressTrailing = trailing;
            }
            
            it("background tint color and size", closure: {
                progressHUD.ag_setupProgressBackgroundView({ (container) in
                    expect(container.backgroundColor?.isEqual(UIColor.red)).to(beTrue())
                    
                    expect(__CGSizeEqualToSize(container.frame.size, progressHUD.frame.size)).to(beTrue())
                })
            })
            
            it("track tint color and size", closure: {
                progressHUD.ag_setupProgressTrackView({ (container) in
                    expect(container.backgroundColor?.isEqual(UIColor.orange)).to(beTrue())
                    
                    expect(__CGSizeEqualToSize(container.frame.size, CGSize.init(width: progressHUD.frame.size.width - leading - trailing, height: height))).to(beTrue())
                })
            })
            
            it("leading view origin and size", closure: {
                progressHUD.ag_setupProgressLeadingView({ (container) in
//                    expect(__CGPointEqualToPoint(container.frame.origin, CGPoint.init(x: leading, y: 0.0))).to(beTrue())
                    
                    expect(__CGSizeEqualToSize(container.frame.size, CGSize.init(width: height, height: height))).to(beTrue())
                })
            })
            
            it("trailing view origin and size", closure: {
                progressHUD.ag_setupProgressTrailingView({ (container) in
                    
                    
                    expect(__CGSizeEqualToSize(container.frame.size, CGSize.init(width: height, height: height))).to(beTrue())
                })
            })
            
            it("current view origin and size", closure: {
                progressHUD.ag_setupProgressTrailingView({ (container) in
                    
                    
                    expect(__CGSizeEqualToSize(container.frame.size, CGSize.init(width: height, height: height))).to(beTrue())
                })
            })
            
        }
        
    }
    
}
