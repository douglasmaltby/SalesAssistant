//
//  ProductClassificationTableViewController.swift
//  SalesAssistant
//
//  Created by Douglas Maltby on 2/23/20.
//  Copyright © 2020 SAP. All rights reserved.
//

import SAPCommon
import SAPFiori
import SAPOData
import UIKit
import Vision

class ProductClassificationTableViewController: UITableViewController, SAPFioriLoadingIndicator {
    var image: UIImage!

    @IBAction func doneButtonTapped(_: Any) {
        self.dismiss(animated: true)
    }

    var loadingIndicator: FUILoadingIndicatorView?

    private var dataService: ESPMContainer<OnlineODataProvider>?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate

    private let logger = Logger.shared(named: "ProductClassificationTableViewController")

    private var products = [Product]()
    private var productImageURLs = [String]()

    private var imageCache = [String: UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension

        tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: FUIObjectTableViewCell.reuseIdentifier)

        guard let dataService = appDelegate.sessionManager.onboardingSession?.odataController.espmContainer else {
            AlertHelper.displayAlert(with: "OData service is not reachable, please onboard again.", error: nil, viewController: self)
            logger.error("OData service is nil. Please check onboarding.")
            return
        }

        self.dataService = dataService

        updateClassifications(for: image)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    private func loadProductImageFrom(_ url: URL, completionHandler: @escaping (_ image: UIImage) -> Void) {
        // Retrieve an instance of the SAPURLSession
        if let sapURLSession = appDelegate.sessionManager.onboardingSession?.sapURLSession {
            // Use a data task on the SAPURLSession to load the product images
            sapURLSession.dataTask(with: url, completionHandler: { data, _, error in

                if let error = error {
                    self.logger.error("Failed to load image!", error: error)
                    return
                }

                if let image = UIImage(data: data!) {
                    // safe image in image cache
                    self.imageCache[url.absoluteString] = image
                    DispatchQueue.main.async { completionHandler(image) }
                }
            }).resume()
        }
    }

    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the Core ML model
            let model = try VNCoreMLModel(for: ProductImageClassifier().model)

            // Create a VNCoreMLRequest passing in the model and starting the classification process in the completionHandler.
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })

            // Crop and scale the image
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()

    /// - Tag: PerformRequests
    func updateClassifications(for image: UIImage) {
        // show the loading indicator
        self.showFioriLoadingIndicator("Finding similar products...")

        // make sure the orientation of the image is passed in the CGImagePropertyOrientation to set the orientation of the image
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        // Create a CIImage as needed by the model for classification. If that fails throw a fatalError.
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }

        // Dispatch to the Global queue to asynchronously perform the classification request.
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }

    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        // Use the main dispatch queue
        DispatchQueue.main.async {
            // Check if the results are nil and display the error in an Alert Dialogue
            guard let results = request.results else {
                self.logger.error("Unable to classify image.", error: error)
                AlertHelper.displayAlert(with: "Unable to classify image.", error: error, viewController: self)
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]

            if classifications.isEmpty {
                AlertHelper.displayAlert(with: "Couldn't recognize the image", error: nil, viewController: self)
            } else {
                // Retrieve top classifications ranked by confidence.
                let topClassifications = classifications.prefix(2)
                let categoryNames = topClassifications.map { classification in
                    String(classification.identifier)
                }

                // Safe unwrap the first classification, because that will be the category with the highest confidence.
                guard let category = categoryNames.first else {
                    AlertHelper.displayAlert(with: "Unable to identify product category", error: nil, viewController: self)
                    self.logger.error("Something went wrong. Please check the classification code.")
                    return
                }

                // Set the Navigation Bar's title to the classified category
                self.navigationItem.title = category

                // Define a DataQuery to only fetch the products matching the classified product category
                let query = DataQuery().filter(Product.category == category)

                // Fetch the products matching the defined query
                self.dataService?.fetchProducts(matching: query) { [weak self] result, error in
                    if let error = error {
                        AlertHelper.displayAlert(with: "Failed to load list of products!", error: error, viewController: self!)
                        self?.logger.error("Failed to load list of products!", error: error)
                        return
                    }

                    // Hide the loading indicator
                    self?.hideFioriLoadingIndicator()
                    self?.products = result!

                    // You will display the product images as well, for that reason create a new array containing the picture urls.
                    self?.productImageURLs = result!.map { $0.pictureUrl ?? "" }
                    self?.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    // Return one section
    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    // Th number of rows is dependent on the available products
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return products.count
    }

    /* - leaving in default override function
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

         // Configure the cell...

         return cell
     }
     */

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get the correct product to display
        let product = products[indexPath.row]

        // Dequeue the FUIObjectTableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: FUIObjectTableViewCell.reuseIdentifier) as! FUIObjectTableViewCell

        // Set the properties of the Object Cell to the name and category name
        cell.headlineText = product.name ?? ""
        cell.subheadlineText = product.categoryName ?? ""

        // If there is a price available, format it using the NumberFormatter and set it to the footnoteText property of the Object Cell.
        if let price = product.price {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let formattedPrice = formatter.string(for: price.intValue())

            cell.footnoteText = formattedPrice ?? ""
        }

        // Because you're using a lazy loading mechanism for displaying the product images to avoid lagging of the Table View, you have to set a placeholder image on the detailImageView property of the Object Cell.
        cell.detailImageView.image = FUIIconLibrary.system.imageLibrary

        // The data service will return the image url in the following format: /imgs/HT-2000.jpg
        // In order to build together the URL you have to define the base URL.
        // The Base URL is found in the Mobile Services API tab.
        let baseURL = "https://hcpms-d061070trial.hanatrial.ondemand.com/com.sap.edm.sampleservice.v2"
        let url = URL(string: baseURL.appending(productImageURLs[indexPath.row]))

        // Safe unwrap the URL, the code above could fail when the URL is not in the correct format, so you have to make sure it is safely unwrapped so you can react accordingly. You won't show the product image if the URL is nil.
        guard let unwrapped = url else {
            logger.info("URL for product image is nil. Returning cell without image.")
            return cell
        }
        // You will use an image cache to cache all already loaded images. If the image is already in the cache display it right out of the cache.
        if let img = imageCache[unwrapped.absoluteString] {
            cell.detailImageView.image = img
        }

        // If the image is not loaded yet, use the loadProductImageFrom(_:) method to load the image from the data service.
        else {
            // The image is not cached yet, so download it.
            loadProductImageFrom(unwrapped) { image in
                cell.detailImageView.image = image
            }
        }

        return cell
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the specified item to be editable.
         return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
         if editingStyle == .delete {
             // Delete the row from the data source
             tableView.deleteRows(at: [indexPath], with: .fade)
         } else if editingStyle == .insert {
             // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
         }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the item to be re-orderable.
         return true
     }
     */

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
