//
// SalesAssistant
//
// Created by SAP Cloud Platform SDK for iOS Assistant application on 17/02/20
//

import Foundation

enum CollectionType: String {
    case products = "Products"
    case productCategories = "ProductCategories"
    case stock = "Stock"
    case purchaseOrderItems = "PurchaseOrderItems"
    case purchaseOrderHeaders = "PurchaseOrderHeaders"
    case suppliers = "Suppliers"
    case productTexts = "ProductTexts"
    case salesOrderHeaders = "SalesOrderHeaders"
    case customers = "Customers"
    case salesOrderItems = "SalesOrderItems"
    case none = ""
    static let all = [products, productCategories, stock, purchaseOrderItems, purchaseOrderHeaders, suppliers, productTexts, salesOrderHeaders, customers, salesOrderItems]
}
