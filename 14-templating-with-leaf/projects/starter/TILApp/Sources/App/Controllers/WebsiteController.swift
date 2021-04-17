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
    routes.get("acronyms", ":acronymID", use: acronymHandler)
    routes.get("users", ":userID", use: userHandler)
    routes.get("users", use: allUsersHandler)
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
  
  func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
    Acronym
      .find(req.parameters.get("acronymID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap({ acronym in
        acronym.$user.get(on: req.db)
          .flatMap({ user in
            let context =
              AcronymContext(
                title: acronym.short,
                acronym: acronym,
                user: user)
            return req.view.render("acronym", context)
          })
      })
  }
  
  func userHandler(_ req: Request) -> EventLoopFuture<View> {
    User
      .find(req.parameters.get("userID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap({ user in
        user
          .$acronyms.get(on: req.db)
          .flatMap({ acronyms in
            let context =
              UserContext(
                title: user.name,
                user: user,
                acronyms: acronyms)
            return req.view.render("user", context)
          })
      })
  }
  
  func allUsersHandler(_ req: Request) -> EventLoopFuture<View> {
    User
      .query(on: req.db)
      .all()
      .flatMap({ users in
        let context =
          AllUsersContext(
            title: "All Users",
            users: users)
        return req.view.render("allUsers", context)
      })
  }
}

struct IndexContext: Encodable {
  let title: String
  let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
  let title: String
  let acronym: Acronym
  let user: User
}

struct UserContext: Encodable {
  let title: String // The title of the page, which is the user’s name.
  let user: User // The user object to which the page refers.
  let acronyms: [Acronym] // The acronyms created by this user.
}

struct AllUsersContext: Encodable {
  let title: String
  let users: [User]
}
