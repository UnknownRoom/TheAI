//
//  NSTextView.swift
//  The AI
//
//  Created by 梓墨 on 2026/4/15.
//
import AppKit
import SwiftUI

struct OnEnterKeyModifier: ViewModifier{
    let action: () -> Void
    @State private var monitor: Any?
    
    func body(content: Content) -> some View {
        content
            .onAppear {              // 这种方式比较底层，通过监控本地事件来拦截
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == 36 || event.keyCode == 76 { // 36 是 Enter 的 KeyCode 76是小键盘Enter KeyCode
                        if event.modifierFlags.contains(.shift) {
                            // Shift + Enter: 允许换行，不拦截return event
                                } else {
                                    if let textView = NSApp.keyWindow?.firstResponder as? NSTextView,
                                               textView.hasMarkedText() {
                                                return event // 输入法正在确认文字，放行
                                            }
                                    action()
                                    return nil // 拦截事件，防止换行
                                        }
                        
                                    }
                                    return event
                                }
                
                            }
                            .onDisappear{
                                if let monitor = monitor{
                                    NSEvent.removeMonitor(monitor)
                                    }
                                }
                            }
                        }
extension View{
    func onEnterPerform(action: @escaping () -> Void) -> some View{
        self.modifier(OnEnterKeyModifier(action: action))
        }
    }
