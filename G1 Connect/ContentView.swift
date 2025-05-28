import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            LilyView()
                .tabItem {
                    Label("Lily", systemImage: "person.circle")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
                .tag(1)

            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(2)
        }
        .accentColor(Constants.primaryColor)
        .onAppear {
            // ViewModel now handles setup
        }
        // Notification for tab switching is now handled in the ViewModel
        // .onReceive(NotificationCenter.default.publisher(for: .evenAIActivated)) { _ in
        //     viewModel.selectedTab = 0
        // }
    }
}

// ContentView_Previews remains the same or can be updated if ContentViewModel needs specific initialization for previews.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
