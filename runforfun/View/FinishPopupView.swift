//
//  FinishPopupView.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import SwiftUI

/// The view displayed when the run is finished
struct FinishPopupView: View {
    var finishTime: String
    var onRepeat: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Text("FINISH!")
                .font(Font.custom("FugazOne-Regular", size: 48))
                .fontWeight(.bold)
                .foregroundColor(.greenPrimary)
                .padding()
            
            Spacer()
            
            VStack {
                Text("You finished the run in")
                    .font(Font.custom("HelveticaNeue-Regular", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.greenPrimary)
                Text("\(finishTime)")
                    .font(Font.custom("HelveticaNeue-Regular", size: 64))
                    .fontWeight(.bold)
                    .foregroundColor(.greenPrimary)
            }
            .padding()
            Spacer()
            Button(action: {
                onRepeat()
                print("Repeat button tapped in FinishPopupView")
            }) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.greenPrimary)
                    .padding()
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: 640, maxHeight: 720)
        .background(Color.blackBg)
        .opacity(0.9)
        .cornerRadius(30)
        .shadow(radius: 10)
        .padding()
    }
}

struct FinishPopupView_Previews: PreviewProvider {
    static var previews: some View {
        FinishPopupView(finishTime: "00:00:00", onRepeat: {})
    }
}
