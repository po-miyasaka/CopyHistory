//
//  FeedbackView.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/11.
//

import SwiftUI

struct FeedbackView: View {
    @State var mailAddress: String = ""
    @State var feedback: String = ""
    @State var isLoading: Bool = false
    @Binding var overlayViewType: MainView.OverlayViewType?
    @State var isAlertPresented: Bool = false
    var body: some View {
        VStack {
            TextField("Mail Address (Optional)", text: $mailAddress).cornerRadius(10).padding(8).border(.clear)
            TextEditor(text: $feedback)
                .overlay(feedback.isEmpty ? Text("Request / Feedback").foregroundColor(.gray).padding(4) : nil, alignment: .topLeading)
                .background(Color.white)
                .cornerRadius(10)
                .opacity(0.8)
                .frame(height: 300)
                .padding(8)
            
            Button(action: {
                Task {
                    isLoading = true
                    await submit()
                }
            }, label: {
                Text("Submit")
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .padding()
            }).buttonStyle(PlainButtonStyle()).disabled(feedback.isEmpty || isLoading)
        }
        .alert(
            isPresented: $isAlertPresented,
            content: {
                Alert(title: Text("Thank you for your feedback!! \n We will put it into practice."), message: nil, dismissButton: Alert.Button.default(
                    Text("OK"),
                    action: {
                        overlayViewType = nil
                    }
                ))
            }
        )
        .overlay(isLoading ? LoadingView() : nil)
    }

    
    func submit() async {
        var urlRequest: URLRequest = .init(url:
                                            URL(string: "https://script.google.com/macros/s/AKfycbz3DShhIzfj91KBFZRwd6-wLkl_m__8GFwW0Fq2aHzu8pGJYgo9ye4ji0x_hbv9X4nG1g/exec")!)
        
        let meta = versionString + "/" + "\(ProcessInfo.processInfo.operatingSystemVersion)" + "/"
        guard let data = try? JSONEncoder().encode(RequestData(content: meta + feedback, address: mailAddress)) else {
            return
        }
        urlRequest.httpBody = data
        urlRequest.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            print(String(data: data, encoding: .utf8) ?? "no data")
            print(response)
            
        } catch {
        }
        isAlertPresented = true
        isLoading = false
        
    }
}

struct RequestData: Codable {
    let content: String
    let address: String
    var appName: String = "CopyHistory"
}

//struct FeedbackView_Previews: PreviewProvider {
//    static var previews: some View {
//        FeedbackView(overlayViewType: .init(get: {nil}, set: {_ in }), isAlertPresented: )
//    }
//}


struct LoadingView: View {
    var body: some View {
        ZStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
        }
    }
}
