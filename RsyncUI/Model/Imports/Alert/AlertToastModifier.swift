//
//  AlertToastModifier.swift
//

import SwiftUI

public struct AlertToastModifier: ViewModifier {
  ///Presentation `Binding<Bool>`
  @Binding var isPresenting: Bool

  ///Duration time to display the alert
  @State var duration: Double = 2

  ///Tap to dismiss alert
  @State var tapToDismiss: Bool = true

  var offsetY: CGFloat = 0

  ///Init `AlertToast` View
  var alert: () -> AlertToast

  ///Completion block returns `true` after dismiss
  var onTap: (() -> Void)? = nil
  var completion: (() -> Void)? = nil

  @State private var workItem: DispatchWorkItem?

  @State private var hostRect: CGRect = .zero
  @State private var alertRect: CGRect = .zero

  private var screen: CGRect {
    #if os(iOS)
      return UIScreen.main.bounds
    #else
      return NSScreen.main?.frame ?? .zero
    #endif
  }

  private var offset: CGFloat {
    return -hostRect.midY + alertRect.height
  }

  @ViewBuilder
  public func main() -> some View {
    if isPresenting {

      switch alert().displayMode {
      case .alert:
        alert()
          .onTapGesture {
            onTap?()
            if tapToDismiss {
              withAnimation(Animation.spring()) {
                self.workItem?.cancel()
                isPresenting = false
                self.workItem = nil
              }
            }
          }
          .onDisappear {
            completion?()
          }
          .transition(AnyTransition.scale(scale: 0.8).combined(with: .opacity))
      case .hud:
        alert()
          .overlay(
            GeometryReader { geo -> EmptyView in
              let rect = geo.frame(in: .global)

              if rect.integral != alertRect.integral {

                DispatchQueue.main.async {

                  self.alertRect = rect
                }
              }
              return EmptyView()
            }
          )
          .onTapGesture {
            onTap?()
            if tapToDismiss {
              withAnimation(Animation.spring()) {
                self.workItem?.cancel()
                isPresenting = false
                self.workItem = nil
              }
            }
          }
          .onDisappear(perform: {
            completion?()
          })
          .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
      case .banner:
        alert()
          .onTapGesture {
            onTap?()
            if tapToDismiss {
              withAnimation(Animation.spring()) {
                self.workItem?.cancel()
                isPresenting = false
                self.workItem = nil
              }
            }
          }
          .onDisappear(perform: {
            completion?()
          })
          .transition(
            alert().displayMode == .banner(.slide)
              ? AnyTransition.slide.combined(with: .opacity) : AnyTransition.move(edge: .bottom))
      }

    }
  }

  @ViewBuilder
  public func body(content: Content) -> some View {
    switch alert().displayMode {
    case .banner:
      content
        .overlay(
          ZStack {
            main()
              .offset(y: offsetY)
          }
          .animation(Animation.spring(), value: isPresenting)
        )
        .onChange(of: isPresenting) { (presented) in
          if presented {
            onAppearAction()
          }
        }
    case .hud:
      content
        .overlay(
          GeometryReader { geo -> EmptyView in
            let rect = geo.frame(in: .global)

            if rect.integral != hostRect.integral {
              DispatchQueue.main.async {
                self.hostRect = rect
              }
            }

            return EmptyView()
          }
          .overlay(
            ZStack {
              main()
                .offset(y: offsetY)
            }
            .frame(maxWidth: screen.width, maxHeight: screen.height)
            .offset(y: offset)
            .animation(Animation.spring(), value: isPresenting))
        )
        .onChange(of: isPresenting) { (presented) in
          if presented {
            onAppearAction()
          }
        }
    case .alert:
      content
        .overlay(
          ZStack {
            main()
              .offset(y: offsetY)
          }
          .frame(maxWidth: screen.width, maxHeight: screen.height, alignment: .center)
          .edgesIgnoringSafeArea(.all)
          .animation(Animation.spring(), value: isPresenting)
        )
        .onChange(of: isPresenting) { (presented) in
          if presented {
            onAppearAction()
          }
        }
    }

  }

  private func onAppearAction() {
    guard workItem == nil else {
      return
    }

    if alert().type == .loading {
      duration = 0
      tapToDismiss = false
    }

    if duration > 0 {
      workItem?.cancel()

      let task = DispatchWorkItem {
        withAnimation(Animation.spring()) {
          isPresenting = false
          workItem = nil
        }
      }
      workItem = task
      DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
  }
}

extension View {
  /// Present `AlertToast`.
  /// - Parameters:
  ///   - show: Binding<Bool>
  ///   - alert: () -> AlertToast
  /// - Returns: `AlertToast`
  public func toast(
    isPresenting: Binding<Bool>,
    duration: Double = 2,
    tapToDismiss: Bool = true,
    offsetY: CGFloat = 0,
    alert: @escaping () -> AlertToast,
    onTap: (() -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) -> some View {
    modifier(
      AlertToastModifier(
        isPresenting: isPresenting,
        duration: duration,
        tapToDismiss: tapToDismiss,
        offsetY: offsetY,
        alert: alert,
        onTap: onTap,
        completion: completion)
    )
  }
}
