//
//  LosePopupView.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import SwiftUI

/// The view displayed when the player hits an obstacle
struct LosePopupView: View {
    var onRepeat: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Text("OOPS!")
                .font(Font.custom("FugazOne-Regular", size: 48))
                .fontWeight(.bold)
                .foregroundColor(.greenPrimary)
            Spacer()
            
            VStack {
                Text("You hit an obstacle")
                    .font(Font.custom("HelveticaNeue-Regular", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.greenPrimary)
                Text("please try again!")
                    .font(Font.custom("HelveticaNeue-Regular", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.greenPrimary)
            }
            Spacer()
            
            Button(action: {
                onRepeat()
                print("Repeat button tapped in LosePopupView")
            }) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.greenPrimary)
            }
            Spacer()
        }
        .frame(maxWidth: 480, maxHeight: 480)
        .background(Color.blackBg)
        .opacity(0.9)
        .cornerRadius(30)
        .shadow(radius: 10)
        .padding()
    }
}

struct LosePopupView_Previews: PreviewProvider {
    static var previews: some View {
        LosePopupView(onRepeat: {})
    }
}
