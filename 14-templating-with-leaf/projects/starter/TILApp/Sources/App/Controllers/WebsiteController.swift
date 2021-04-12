//
//  File.swift
//  
//
//  Created by 🤨 on 11/04/21.
//

import Vapor
import Leaf

struct WebsiteController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: indexHandler)
  }

  func indexHandler(_ req: Request) -> EventLoopFuture<View> {
    Acronym.query(on: req.db).all().flatMap({ acronyms in
      let acronymsData = acronyms.isEmpty ? nil : acronyms
      let context = IndexContext(
        title: "Home page",
        acronyms: acronymsData
      )
      return req.view.render("index", context)
    })
  }
}

struct IndexContext: Encodable {
  let title: String
  let acronyms: [Acronym]?
}
