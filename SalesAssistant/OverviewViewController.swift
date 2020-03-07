//
//  OverviewViewController.swift
//  SalesAssistant
//
//  Created by Douglas Maltby on 2/17/20.
//  Copyright © 2020 SAP. All rights reserved.
//

import SAPCommon
import SAPFiori
import SAPOData
import UIKit

class OverviewViewController: UIViewController, SAPFioriLoadingIndicator {
    // The data service is called ESPMContainer here and because you're using Online OData you have to define the data service as OnlineODataProvider.
    private var dataService: ESPMContainer<OnlineODataProvider>?

    // The AppDelegate is easily accessible through the UIApplication instance.
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate

    // The Logger is already setup in the AppDelegate through the SAP iOS Assistant, that's why we can easily can get an instance here.
    private let logger = Logger.shared(named: "OverviewViewController")

    private var customers = [Customer]()
    private var products = [Product]()

    var loadingIndicator: FUILoadingIndicatorView?

    private let showCustomerDetailSegue = "showCustomerDetail"
    private let showProductClassificationSegue = "showProductClassification"

    private let pickerController = UIImagePickerController()
    private var pickedImage: UIImage!

    @IBOutlet var tableView: UITableView!
    @IBOutlet var actionListButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Remember when you set the top constraint to 25? - This code will set  the background color of the View Controller's view to the standard background color defined in the SAP Fiori for iOS Design Guidelines. This will cause the space up top to appear as a visual divider.
        self.view.backgroundColor = .preferredFioriColor(forStyle: .backgroundBase)

        // Using the FUI Icon Library
        actionListButton.image = FUIIconLibrary.system.more

        // Define the estimated row height for each row as well as setting the actual row height to define it's dimension itself.
        // This will cause the Table View to display a cell for at least 80 points.
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension

        // Register an FUIObjectTableViewCell and a FUITableViewHeaderFooterView. We can use the convenience reuse identifier defined in the cell classes to later dequeue the cells.
        tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: FUIObjectTableViewCell.reuseIdentifier)
        tableView.register(FUITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: FUITableViewHeaderFooterView.reuseIdentifier)

        tableView.delegate = self
        tableView.dataSource = self

        guard let dataService = appDelegate.sessionManager.onboardingSession?.odataController.espmContainer else {
            AlertHelper.displayAlert(with: "OData service is not reachable, please onboard again.", error: nil, viewController: self)
            logger.error("OData service is nil. Please check onboarding.")
            return
        }
        self.dataService = dataService
        setupImagePicker()
        loadInitialData()
        // Do any additional setup after loading the view.
    }

    private func loadInitialData() {
        // start showing the loading indicator
        self.showFioriLoadingIndicator()

        // Using a DispatchGroup will help you to get notified when all the needed data sets are loaded
        let group = DispatchGroup()

        // Fetch customers and products, pass in the DispatchGroup to handle entering and leaving of the group
        fetchCustomers(group)

        fetchProducts(group)

        // When all data tasks are completed, hide the loading indicator and reload the table view. This will cause a refresh of the UI, displaying the newly loaded data
        group.notify(queue: DispatchQueue.main) {
            self.hideFioriLoadingIndicator()
            self.tableView.reloadData()
        }
    }

    private func fetchCustomers(_ group: DispatchGroup) {
        // Enter the DispatchGroup
        group.enter()

        // Define a Data Query which is a class of the SAPOData framework. This query will tell the OData Service to also load the available Sales Orders for each Customer
        let query = DataQuery().expand(Customer.salesOrders)

        // Now call the data service and fetch the customers matching the above defined query. When during runtime the block gets entered we expect a result or an error. Also you want to hold a weak reference of self to not run into object reference issues during runtime.
        dataService?.fetchCustomers(matching: query) { [weak self] result, error in

            // If there is an error show an AlertDialog using the generated convenience class AlertHelper. Also log the error to the console and leave the /group.
            if let error = error {
                AlertHelper.displayAlert(with: "Failed to load list of customers!", error: error, viewController: self!)
                self?.logger.error("Failed to load list of customers!", error: error)
                group.leave()
                return
            }
            // sort the customer result set by the number of available sales orders by customer.
            self?.customers = result!.sorted(by: { $0.salesOrders.count > $1.salesOrders.count })

            group.leave()
        }
    }

    private func fetchProducts(_ group: DispatchGroup) {
        // Enter the DispatchGroup
        group.enter()

        // Define a Data Query only fetching the top 5 products.
        let query = DataQuery().top(5)

        dataService?.fetchProducts(matching: query) { [weak self] result, error in
            if let error = error {
                AlertHelper.displayAlert(with: "Failed to load list of products!", error: error, viewController: self!)
                self?.logger.error("Failed to load list of products!", error: error)
                group.leave()
                return
            }
            self?.products = result!
            group.leave()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // Implement a switch over the segue identifiers to distinct which segue get's called.
        if segue.identifier == showCustomerDetailSegue {
            // Show the selected Customer on the Detail view
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }

            // Retrieve the selected customer
            let selectedEntity = self.customers[indexPath.row]

            // Get an instance of the CustomerDetailTableViewController with asking the segue for it's destination.
            let detailViewController = segue.destination as! CustomerDetailTableViewController

            // Check if the customer ID is set, if not handle the errors and notify the user.
            guard let customerID = selectedEntity.customerID else {
                AlertHelper.displayAlert(with: "We're having issues displaying the details for the customer with name \(selectedEntity.lastName ?? "")", error: nil, viewController: self)
                self.logger.error("Unexpectedly customerID is nil! Can't pass customerID into CustomerDetailViewController.")
                return
            }

            // Set the customer ID at the CustomerDetailTableViewController.
            detailViewController.customerId = customerID

            // Set the title of the navigation item on the CustomerDetailTableViewController
            detailViewController.navigationItem.title = "\(self.customers[indexPath.row].firstName ?? ""), \(self.customers[indexPath.row].lastName ?? "")"
        }
        if segue.identifier == showProductClassificationSegue {
            let navController = segue.destination as! UINavigationController
            let productPredictionVC = navController.children.first! as! ProductClassificationTableViewController
            productPredictionVC.image = pickedImage
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */

    @IBAction func didPressActionListButton(_ sender: UIBarButtonItem) {
        // You will use an Action Sheet and Pop-Over on regular mode on iPad
        // Create an UIAlertController with the preferred style actionSheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Define the image sources as a tuple having a description and the actual source type
        let imageSources = [
            ("Using Camera", UIImagePickerController.SourceType.camera),
            ("Based on Photo", UIImagePickerController.SourceType.photoLibrary),
        ]

        // Iterate over the tuple and create an UIAlertAction accordingly. Add those actions to the alertController
        for (sourceName, sourceType) in imageSources where UIImagePickerController.isSourceTypeAvailable(sourceType) {
            alertController.addAction(UIAlertAction(title: "Find Product \(sourceName)", style: .default) { _ in
                self.pickerController.sourceType = sourceType
                self.present(self.pickerController, animated: true)
            })
        }

        // Add a cancel action as well for the user to cancel the alertController
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // If in a regular layout on iPad, show as a popover
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }

        // Present the alertController
        self.present(alertController, animated: true)
    }

    private func setupImagePicker() {
        pickerController.delegate = self
        pickerController.allowsEditing = false

        // Only allow images here
        pickerController.mediaTypes = ["public.image"]
    }
}

extension OverviewViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // First dequeue the Header Footer View you registered in the viewDidLoad(:).
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: FUITableViewHeaderFooterView.reuseIdentifier) as! FUITableViewHeaderFooterView

        // Set it's style to title.
        header.style = .title
        header.separators = .bottom

        // For the first section give back a Header that is for the customers and the second is for the products
        switch section {
        case 0:
            header.titleLabel.text = "Customers"
        case 1:
            header.titleLabel.text = "Products"
        default:
            break
        }

        return header
    }

    func tableView(_: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1 { return UIView() }

        let divider = UITableViewHeaderFooterView()
        divider.backgroundColor = .preferredFioriColor(forStyle: .backgroundBase)

        return divider
    }

    // If the data arrays are empty return 0, else return 5.
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if customers.isEmpty { return 0 }
        case 1:
            if products.isEmpty { return 0 }
        default:
            return 0
        }

        return 5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue the FUIObjectTableViewCell and cast it accordingly.
        let cell = tableView.dequeueReusableCell(withIdentifier: FUIObjectTableViewCell.reuseIdentifier) as! FUIObjectTableViewCell

        // Set the accessory type of the cell to disclosure, this will indicate to the user that those cells are tappable.
        cell.accessoryType = .disclosureIndicator

        // Distinct the cell setup depending on the section.
        switch indexPath.section {
        case 0:

            // Get the currently needed customer and fill the cell's properties
            let customer = customers[indexPath.row]
            cell.headlineText = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
            cell.subheadlineText = "\(customer.city ?? ""), \(customer.country ?? "")"
            cell.footnoteText = "# Sales Orders : \(customer.salesOrders.count)"
            return cell
        case 1:

            // Get the currently needed product and fill the cell's properties
            let product = products[indexPath.row]
            cell.headlineText = product.name ?? ""
            cell.subheadlineText = product.categoryName ?? ""

            // If there is a product price set, format it with the help of a NumberFormatter
            if let price = product.price {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                let formattedPrice = formatter.string(for: price.intValue())

                cell.footnoteText = formattedPrice ?? ""
            }

            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 { performSegue(withIdentifier: showCustomerDetailSegue, sender: tableView.cellForRow(at: indexPath)) }
    }
}

extension OverviewViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // If the Image Picker Controller did get cancelled, just dismiss the Image Picker Controller
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    // If the user picked an image check if the image can be unwrapped to an UIImage, if not log an error and dismiss the Image Picker
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            logger.error("Image is nil! Please check UIImagePicker implementation.")
            return picker.dismiss(animated: true, completion: nil)
        }

        // If all went good, please assign the picked image to the pickedImage property, dismiss the the Image Picker and perform the segue to the classification View Controller
        pickedImage = image
        picker.dismiss(animated: true) {
            self.performSegue(withIdentifier: self.showProductClassificationSegue, sender: self)
        }
    }
}
