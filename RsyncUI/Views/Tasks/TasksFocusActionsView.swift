import SwiftUI

struct TasksFocusActionsView: View {
    @Binding var focusStartEstimation: Bool
    @Binding var focusStartExecution: Bool
    @Binding var doubleClick: Bool

    let onStartEstimation: () -> Void
    let onStartExecution: () -> Void
    let onDoubleClick: () -> Void

    var body: some View {
        Group {
            if focusStartEstimation { triggerStartEstimation }
            if focusStartExecution { triggerStartExecution }
            if doubleClick { triggerDoubleClick }
        }
    }

    private var triggerStartEstimation: some View {
        Label("", systemImage: "play.fill")
            .foregroundStyle(.black)
            .onAppear {
                onStartEstimation()
                focusStartEstimation = false
            }
    }

    private var triggerStartExecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundStyle(.black)
            .onAppear {
                onStartExecution()
                focusStartExecution = false
            }
    }

    private var triggerDoubleClick: some View {
        Label("", systemImage: "play.fill")
            .foregroundStyle(.black)
            .onAppear {
                onDoubleClick()
                doubleClick = false
            }
    }
}
