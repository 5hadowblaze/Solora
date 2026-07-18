import SwiftUI

struct ArchiveView: View {
    let moments: [SoloraMoment]
    var body: some View {
        NavigationStack {
            List(moments) { MomentRow(moment: $0) }
                .navigationTitle("Archive")
        }
    }
}
