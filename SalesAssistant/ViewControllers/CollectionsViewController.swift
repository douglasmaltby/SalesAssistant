//
// SalesAssistant
//
// Created by SAP Cloud Platform SDK for iOS Assistant application on 17/02/20
//

import Foundation
import SAPFiori
import SAPFioriFlows
import SAPOData

protocol EntityUpdaterDelegate {
    func entityHasChanged(_ entity: EntityValue?)
}

protocol EntitySetUpdaterDelegate {
    func entitySetHasChanged()
}

class CollectionsViewController: FUIFormTableViewController {
    private var collections = CollectionType.all

    // Variable to store the selected index path
    private var selectedIndex: IndexPath?

    private let okTitle = NSLocalizedString("keyOkButtonTitle",
                                            value: "OK",
                                            comment: "XBUT: Title of OK button.")

    var isPresentedInSplitView: Bool {
        return !(self.splitViewController?.isCollapsed ?? true)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 320, height: 480)

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.makeSelection()
    }

    override func viewWillTransition(to _: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            let isNotInSplitView = !self.isPresentedInSplitView
            self.tableView.visibleCells.forEach { cell in
                // To refresh the disclosure indicator of each cell
                cell.accessoryType = isNotInSplitView ? .disclosureIndicator : .none
            }
            self.makeSelection()
        })
    }

    // MARK: - UITableViewDelegate

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return collections.count
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUIObjectTableViewCell.reuseIdentifier, for: indexPath) as! FUIObjectTableViewCell
        cell.headlineLabel.text = self.collections[indexPath.row].rawValue
        cell.accessoryType = !self.isPresentedInSplitView ? .disclosureIndicator : .none
        cell.isMomentarySelection = false
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.collectionSelected(at: indexPath)
    }

    // CollectionType selection helper
    private func collectionSelected(at indexPath: IndexPath) {
        // Load the EntityType specific ViewController from the specific storyboard"
        var masterViewController: UIViewController!
        guard let espmContainer = OnboardingSessionManager.shared.onboardingSession?.odataController.espmContainer else {
            AlertHelper.displayAlert(with: "OData service is not reachable, please onboard again.", error: nil, viewController: self)
            return
        }
        self.selectedIndex = indexPath

        switch self.collections[indexPath.row] {
        case .products:
            let productStoryBoard = UIStoryboard(name: "Product", bundle: nil)
            let productMasterViewController = productStoryBoard.instantiateViewController(withIdentifier: "ProductMaster") as! ProductMasterViewController
            productMasterViewController.espmContainer = espmContainer
            productMasterViewController.entitySetName = "Products"
            func fetchProducts(_ completionHandler: @escaping ([Product]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchProducts(matching: query, completionHandler: completionHandler)
                }
            }
            productMasterViewController.loadEntitiesBlock = fetchProducts
            productMasterViewController.navigationItem.title = "Product"
            masterViewController = productMasterViewController
        case .productCategories:
            let productCategoryStoryBoard = UIStoryboard(name: "ProductCategory", bundle: nil)
            let productCategoryMasterViewController = productCategoryStoryBoard.instantiateViewController(withIdentifier: "ProductCategoryMaster") as! ProductCategoryMasterViewController
            productCategoryMasterViewController.espmContainer = espmContainer
            productCategoryMasterViewController.entitySetName = "ProductCategories"
            func fetchProductCategories(_ completionHandler: @escaping ([ProductCategory]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchProductCategories(matching: query, completionHandler: completionHandler)
                }
            }
            productCategoryMasterViewController.loadEntitiesBlock = fetchProductCategories
            productCategoryMasterViewController.navigationItem.title = "ProductCategory"
            masterViewController = productCategoryMasterViewController
        case .stock:
            let stockStoryBoard = UIStoryboard(name: "Stock", bundle: nil)
            let stockMasterViewController = stockStoryBoard.instantiateViewController(withIdentifier: "StockMaster") as! StockMasterViewController
            stockMasterViewController.espmContainer = espmContainer
            stockMasterViewController.entitySetName = "Stock"
            func fetchStock(_ completionHandler: @escaping ([Stock]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchStock(matching: query, completionHandler: completionHandler)
                }
            }
            stockMasterViewController.loadEntitiesBlock = fetchStock
            stockMasterViewController.navigationItem.title = "Stock"
            masterViewController = stockMasterViewController
        case .purchaseOrderItems:
            let purchaseOrderItemStoryBoard = UIStoryboard(name: "PurchaseOrderItem", bundle: nil)
            let purchaseOrderItemMasterViewController = purchaseOrderItemStoryBoard.instantiateViewController(withIdentifier: "PurchaseOrderItemMaster") as! PurchaseOrderItemMasterViewController
            purchaseOrderItemMasterViewController.espmContainer = espmContainer
            purchaseOrderItemMasterViewController.entitySetName = "PurchaseOrderItems"
            func fetchPurchaseOrderItems(_ completionHandler: @escaping ([PurchaseOrderItem]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchPurchaseOrderItems(matching: query, completionHandler: completionHandler)
                }
            }
            purchaseOrderItemMasterViewController.loadEntitiesBlock = fetchPurchaseOrderItems
            purchaseOrderItemMasterViewController.navigationItem.title = "PurchaseOrderItem"
            masterViewController = purchaseOrderItemMasterViewController
        case .purchaseOrderHeaders:
            let purchaseOrderHeaderStoryBoard = UIStoryboard(name: "PurchaseOrderHeader", bundle: nil)
            let purchaseOrderHeaderMasterViewController = purchaseOrderHeaderStoryBoard.instantiateViewController(withIdentifier: "PurchaseOrderHeaderMaster") as! PurchaseOrderHeaderMasterViewController
            purchaseOrderHeaderMasterViewController.espmContainer = espmContainer
            purchaseOrderHeaderMasterViewController.entitySetName = "PurchaseOrderHeaders"
            func fetchPurchaseOrderHeaders(_ completionHandler: @escaping ([PurchaseOrderHeader]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchPurchaseOrderHeaders(matching: query, completionHandler: completionHandler)
                }
            }
            purchaseOrderHeaderMasterViewController.loadEntitiesBlock = fetchPurchaseOrderHeaders
            purchaseOrderHeaderMasterViewController.navigationItem.title = "PurchaseOrderHeader"
            masterViewController = purchaseOrderHeaderMasterViewController
        case .suppliers:
            let supplierStoryBoard = UIStoryboard(name: "Supplier", bundle: nil)
            let supplierMasterViewController = supplierStoryBoard.instantiateViewController(withIdentifier: "SupplierMaster") as! SupplierMasterViewController
            supplierMasterViewController.espmContainer = espmContainer
            supplierMasterViewController.entitySetName = "Suppliers"
            func fetchSuppliers(_ completionHandler: @escaping ([Supplier]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchSuppliers(matching: query, completionHandler: completionHandler)
                }
            }
            supplierMasterViewController.loadEntitiesBlock = fetchSuppliers
            supplierMasterViewController.navigationItem.title = "Supplier"
            masterViewController = supplierMasterViewController
        case .productTexts:
            let productTextStoryBoard = UIStoryboard(name: "ProductText", bundle: nil)
            let productTextMasterViewController = productTextStoryBoard.instantiateViewController(withIdentifier: "ProductTextMaster") as! ProductTextMasterViewController
            productTextMasterViewController.espmContainer = espmContainer
            productTextMasterViewController.entitySetName = "ProductTexts"
            func fetchProductTexts(_ completionHandler: @escaping ([ProductText]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchProductTexts(matching: query, completionHandler: completionHandler)
                }
            }
            productTextMasterViewController.loadEntitiesBlock = fetchProductTexts
            productTextMasterViewController.navigationItem.title = "ProductText"
            masterViewController = productTextMasterViewController
        case .salesOrderHeaders:
            let salesOrderHeaderStoryBoard = UIStoryboard(name: "SalesOrderHeader", bundle: nil)
            let salesOrderHeaderMasterViewController = salesOrderHeaderStoryBoard.instantiateViewController(withIdentifier: "SalesOrderHeaderMaster") as! SalesOrderHeaderMasterViewController
            salesOrderHeaderMasterViewController.espmContainer = espmContainer
            salesOrderHeaderMasterViewController.entitySetName = "SalesOrderHeaders"
            func fetchSalesOrderHeaders(_ completionHandler: @escaping ([SalesOrderHeader]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchSalesOrderHeaders(matching: query, completionHandler: completionHandler)
                }
            }
            salesOrderHeaderMasterViewController.loadEntitiesBlock = fetchSalesOrderHeaders
            salesOrderHeaderMasterViewController.navigationItem.title = "SalesOrderHeader"
            masterViewController = salesOrderHeaderMasterViewController
        case .customers:
            let customerStoryBoard = UIStoryboard(name: "Customer", bundle: nil)
            let customerMasterViewController = customerStoryBoard.instantiateViewController(withIdentifier: "CustomerMaster") as! CustomerMasterViewController
            customerMasterViewController.espmContainer = espmContainer
            customerMasterViewController.entitySetName = "Customers"
            func fetchCustomers(_ completionHandler: @escaping ([Customer]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchCustomers(matching: query, completionHandler: completionHandler)
                }
            }
            customerMasterViewController.loadEntitiesBlock = fetchCustomers
            customerMasterViewController.navigationItem.title = "Customer"
            masterViewController = customerMasterViewController
        case .salesOrderItems:
            let salesOrderItemStoryBoard = UIStoryboard(name: "SalesOrderItem", bundle: nil)
            let salesOrderItemMasterViewController = salesOrderItemStoryBoard.instantiateViewController(withIdentifier: "SalesOrderItemMaster") as! SalesOrderItemMasterViewController
            salesOrderItemMasterViewController.espmContainer = espmContainer
            salesOrderItemMasterViewController.entitySetName = "SalesOrderItems"
            func fetchSalesOrderItems(_ completionHandler: @escaping ([SalesOrderItem]?, Error?) -> Void) {
                // Only request the first 20 values. If you want to modify the requested entities, you can do it here.
                let query = DataQuery().selectAll().top(20)
                do {
                    espmContainer.fetchSalesOrderItems(matching: query, completionHandler: completionHandler)
                }
            }
            salesOrderItemMasterViewController.loadEntitiesBlock = fetchSalesOrderItems
            salesOrderItemMasterViewController.navigationItem.title = "SalesOrderItem"
            masterViewController = salesOrderItemMasterViewController
        case .none:
            masterViewController = UIViewController()
        }

        // Load the NavigationController and present with the EntityType specific ViewController
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let rightNavigationController = mainStoryBoard.instantiateViewController(withIdentifier: "RightNavigationController") as! UINavigationController
        rightNavigationController.viewControllers = [masterViewController]
        self.splitViewController?.showDetailViewController(rightNavigationController, sender: nil)
    }

    // MARK: - Handle highlighting of selected cell

    private func makeSelection() {
        if let selectedIndex = selectedIndex {
            tableView.selectRow(at: selectedIndex, animated: true, scrollPosition: .none)
            tableView.scrollToRow(at: selectedIndex, at: .none, animated: true)
        } else {
            selectDefault()
        }
    }

    private func selectDefault() {
        // Automatically select first element if we have two panels (iPhone plus and iPad only)
        if self.splitViewController!.isCollapsed || OnboardingSessionManager.shared.onboardingSession?.odataController.espmContainer == nil {
            return
        }
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        self.collectionSelected(at: indexPath)
    }
}
