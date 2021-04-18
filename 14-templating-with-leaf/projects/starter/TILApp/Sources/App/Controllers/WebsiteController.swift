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
    routes.get("categories", use: allCategoriesHandler)
    routes.get("categories", ":categoryID", use: categoryHandler)
  }

  func indexHandler(_ req: Request) -> EventLoopFuture<View> {
    Acronym.query(on: req.db).all().flatMap({ acronyms in
      let context = IndexContext(
        title: "Home page",
        acronyms: acronyms
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
  
  func allCategoriesHandler(_ req: Request) -> EventLoopFuture<View> {
    Category
      .query(on: req.db)
      .all()
      .flatMap { categories in
        let context =
          AllCategoriesContext(
            categories: categories)
        return req.view.render("allCategories", context)
      }
  }
  
  func categoryHandler(_ req: Request) -> EventLoopFuture<View> {
    Category
      .find(req.parameters.get("categoryID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { category in
        category.$acronyms.get(on: req.db).flatMap { acronyms in
          let context =
            CategoryContext(
              title: category.name,
              category: category,
              acronyms: acronyms)
          return req.view.render("category", context)
        }
    }
  }

}

struct IndexContext: Encodable {
  let title: String
  let acronyms: [Acronym]
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

struct AllCategoriesContext: Encodable {
  let title = "All Categories"
  let categories: [Category]
}

struct CategoryContext: Encodable {
  let title: String
  let category: Category
  let acronyms: [Acronym]
}
