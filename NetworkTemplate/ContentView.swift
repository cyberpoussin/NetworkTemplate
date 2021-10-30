//
//  ContentView.swift
//  NetworkTemplate
//
//  Created by Admin on 12/10/2021.
//

import Combine
import SwiftUI
struct ContentView: View {
    let session = APISession()
    @State private var cancellable: AnyCancellable?
    @State private var dlPercentage: Double?
    @State private var ulPercentage: Double?

    @State private var uiimage: UIImage?

    var body: some View {
        VStack {
            Button("Receive") {
                let request = URLRequest(url: URL(string: "https://effigis.com/wp-content/uploads/2015/02/DigitalGlobe_WorldView1_50cm_8bit_BW_DRA_Bangkok_Thailand_2009JAN06_8bits_sub_r_1.jpg")!)

                cancellable = session
                    .download(request: request)
                    
                    .replaceError(with: FileResponse.progress(percentage: 0))
                    .sink { response in
                        switch response {
                        case let .progress(percentage):
                            self.dlPercentage = percentage
                        case let .data(data):
                            self.uiimage = UIImage(data: data)
                        }
                        
                    }
            }
            Button("send") {
                guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TempImage.png") else {
                    return
                }

                let pngData = UIImage(named: "pass")!.pngData()
                do {
                    try pngData?.write(to: imageURL)
                } catch { }
                var request = URLRequest(url: URL(string: "https://ptsv2.com/t/networkTemplateGet/post")!)
                request.httpMethod = "POST"

                cancellable = session
                    .upload(request: request, fileURL: imageURL)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case let .failure(error):
                            print(error)
                            print("erreur")
                        default: print("fini des fins")
                        }
                    }, receiveValue: { value in
                        switch value {
                        case let .progress(percentage):
                            ulPercentage = percentage
                        default:
                            break
                        }
                    })
            }
            Text(dlPercentage?.description ?? "rien")
            Text(ulPercentage?.description ?? "rien")

            if let uiimage = uiimage {
                Image(uiImage: uiimage)
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
