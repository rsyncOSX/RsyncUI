//
//  NewOpencatalogView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/03/2025.
//

import SwiftUI

struct NewOpencatalogView: View {
    
    @Binding var catalog: String    
    @State private var isImporting: Bool = false
    
    let catalogs: Bool
    
    var body: some View {
        
        if catalogs {
            Button(action: {
                isImporting = true
            }, label: {
                Image(systemName: "folder")
                    .foregroundColor(Color(.blue))
            })
            .fileImporter(isPresented: $isImporting,
                          allowedContentTypes: [.directory],
                          onCompletion: { result in
                
                switch result {
                case .success(let url):
                    catalog = url.relativePath
                case .failure(let error):
                    SharedReference.shared.errorobject?.alert(error: error)
                }
            })
        } else {
            Button(action: {
                isImporting = true
            }, label: {
                Image(systemName: "folder")
                    .foregroundColor(Color(.blue))
            })
            .fileImporter(isPresented: $isImporting,
                          allowedContentTypes: [.item],
                          onCompletion: { result in
                
                switch result {
                case .success(let url):
                    catalog = url.relativePath
                case .failure(let error):
                    SharedReference.shared.errorobject?.alert(error: error)
                }
            })
        }
    }
}
