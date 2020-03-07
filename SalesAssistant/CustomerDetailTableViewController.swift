//
//  CustomerDetailTableViewController.swift
//  SalesAssistant
//
//  Created by Douglas Maltby on 2/17/20.
//  Copyright © 2020 SAP. All rights reserved.
//

import SAPCommon
import SAPFiori
import SAPOData
import UIKit

class CustomerDetailTableViewController: UITableViewController, SAPFioriLoadingIndicator {
    private var dataService: ESPMContainer<OnlineODataProvider>?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate

    private let logger = Logger.shared(named: "CustomerDetailTableViewController")

    var loadingIndicator: FUILoadingIndicatorView?

    private let profileHeader = FUIProfileHeader()

    var customerId: String!

    // The Sales Order Headers property is an Array.
    private var salesOrderHeaders = [SalesOrderHeader]() {
        // When that property is set through the loadData() make the needed calculations
        didSet {
            // With help of the map call on the array you can access the net amount property of the Sales Order Header of each element in the array, make the calculation and safe it in the Series Data property needed for the Chart.
            seriesData = [salesOrderHeaders.map {
                guard let net = $0.netAmount?.doubleValue() else {
                    return 0.0
                }
                return net
            }]
        }
    }

    private var customer = Customer()
    private var isDataLoaded = false

    private var seriesData: [[Double]]?

    private var chartData = (
        series: ["2018"],
        categories: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let dataService = appDelegate.sessionManager.onboardingSession?.odataController.espmContainer else {
            AlertHelper.displayAlert(with: "OData service is not reachable, please onboard again.", error: nil, viewController: self)
            logger.error("OData service is nil. Please check onboarding.")
            return
        }
        self.dataService = dataService

        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none

        // The Object Cell is used for the case if there are no Customer Sales Headers available for the chosen customer
        tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: FUIObjectTableViewCell.reuseIdentifier)

        // Used to display the title information for the Chart
        tableView.register(FUIChartTitleTableViewCell.self, forCellReuseIdentifier: FUIChartTitleTableViewCell.reuseIdentifier)

        // Used to display the Chart itself
        tableView.register(FUIChartPlotTableViewCell.self, forCellReuseIdentifier: FUIChartPlotTableViewCell.reuseIdentifier)

        // Used to display the Chart legend
        tableView.register(FUIChartLegendTableViewCell.self, forCellReuseIdentifier: FUIChartLegendTableViewCell.reuseIdentifier)

        updateTable()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    // MARK: - Data loading methods

    private func updateTable() {
        // Show the loading indicator
        self.showFioriLoadingIndicator()

        // Wait for the completion handler to get executed and hide the loading indicator
        self.loadData {
            self.hideFioriLoadingIndicator()

            // You will implement that method in the next steps, for now please just call it here.
            self.setupProfileHeader()

            // Reload the Table View to show the newly fetched data
            self.tableView.reloadData()
        }
    }

    // Load the Customer for the set Customer ID
    private func loadData(completionHandler: @escaping () -> Void) {
        // Expand the OData call to also retrieve the Customers Sales Orders as you're going to display those in the Chart.
        let query = DataQuery().expand(Customer.salesOrders)

        // Fetch the customer with a certain ID
        dataService?.fetchCustomerWithKey(customerID: customerId, query: query) { [weak self] result, error in

            // If there is an error let the user know and log it to the console.
            if let error = error {
                AlertHelper.displayAlert(with: "Couldn't load sales orders for customer.", error: error, viewController: self!)
                self?.logger.error("Couldn't load sales orders for customer.", error: error)
                return
            }

            // Set the result to a customer property
            self?.customer = result!

            // Set the retrieved Sales Orders to it's property
            self?.salesOrderHeaders = result!.salesOrders

            // You will need this property later for the Charts.
            self?.isDataLoaded = true

            // Execute the Completion Handler
            completionHandler()
        }
    }

    // MARK: - UITableViewDataSource implementation

    // Return the number of total sections for the TableView, as you're only going to display one section for the Chart cells return 1.
    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    // Return a divider header with the Fiori color .primary4 (Hex color: CCCCCC)
    override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.backgroundColor = .preferredFioriColor(forStyle: .primary4)

        return header
    }

    // The number of rows is 3 for the three registered cells. In case the Sales Order Headers are empty just return 1 for the Object cell.
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if salesOrderHeaders.isEmpty { return 1 }
        return 3
    }

    // Dequeue the needed cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // If the Sales Orders are empty and the data is already loaded return an Object Cell informing the user about that no data is available.
        // If the Data is not loaded yet, just return an empty UITableViewCell.
        if salesOrderHeaders.isEmpty {
            if isDataLoaded {
                let cell = tableView.dequeueReusableCell(withIdentifier: FUIObjectTableViewCell.reuseIdentifier) as! FUIObjectTableViewCell
                cell.headlineText = "No Sales Orders available for this customer."
                return cell
            } else {
                return UITableViewCell()
            }
        }

        // Because you know, that there are only 3 cells going to be displayed you can switch over those 3 rows and make sure to dequeue the correct cells.
        // Note: You could also use static Table View Cells and create outlets for them to populate them directly.
        switch indexPath.row {
        case 0:
            // The first cell is the Chart Title Cell, it will just get a title containing the currency code
            let cell = tableView.dequeueReusableCell(withIdentifier: FUIChartTitleTableViewCell.reuseIdentifier) as! FUIChartTitleTableViewCell
            cell.title.text = "Net Amount (\(salesOrderHeaders.first?.currencyCode ?? "")) for Sales Orders"
            return cell
        case 1:
            // The second cell is the actual Chart Plot cell, setup the chart as a Line Chart and set it's Data Source and Delegate to this View Controller.
            let cell = tableView.dequeueReusableCell(withIdentifier: FUIChartPlotTableViewCell.reuseIdentifier) as! FUIChartPlotTableViewCell
            cell.valuesAxisTitle.text = "Net Amount (\(salesOrderHeaders.first?.currencyCode ?? ""))"
            cell.categoryAxisTitle.text = "Date"
            cell.chartView.categoryAxis.labelLayoutStyle = .range
            cell.chartView.chartType = .line
            cell.chartView.dataSource = self
            cell.chartView.delegate = self
            return cell
        case 2:
            // The third and last cell is for the Chart Legend. Set the year hardcoded here and set the line color to Chart1 (Hex color: 5899DA).
            let cell = tableView.dequeueReusableCell(withIdentifier: FUIChartLegendTableViewCell.reuseIdentifier) as! FUIChartLegendTableViewCell
            cell.seriesTitles = ["2018"]
            cell.seriesColor = [.preferredFioriColor(forStyle: .chart1)]
            return cell
        default:
            // You have to provide a default case here, just dequeue an Object Cell which will let the user know that something went wrong. This case should never appear if you have implemented the Data Source correctly.
            let cell = tableView.dequeueReusableCell(withIdentifier: FUIObjectTableViewCell.reuseIdentifier) as! FUIObjectTableViewCell
            cell.headlineText = "There was an issue while creating the chart!"
            return cell
        }
    }

    // MARK: - Profile Header setup

    private func setupProfileHeader() {
        // first format the birthday of the customer as we want to display that date in the Profile Header
        let dateOfBirth = customer.dateOfBirth?.utc()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let date = dateOfBirth {
            let formattedDate = formatter.string(from: date)
            profileHeader.headlineText = "Birthday: \(formattedDate)"
        }

        profileHeader.subheadlineText = "\(customer.street ?? ""), \(customer.city ?? ""), \(customer.postalCode ?? ""), \(customer.country ?? "")"

        // The split percentage will indicate how the content is supposed to be distributed inside the Profile Header.
        profileHeader.splitPercent = 0.3

        // The Activity Control is a great UI control for making direct calls, text messages or emails to the Customer.
        let activityControl = FUIActivityControl()
        activityControl.addActivities([.phone, .message, .email])
        activityControl.activityItems[.phone]?.setTitleColor(.preferredFioriColor(forStyle: .tintColorDark), for: .normal)
        activityControl.activityItems[.message]?.setTitleColor(.preferredFioriColor(forStyle: .tintColorDark), for: .normal)
        activityControl.activityItems[.email]?.setTitleColor(.preferredFioriColor(forStyle: .tintColorDark), for: .normal)

        // Set this View Controller as Delegate for the Activity Control
        activityControl.delegate = self
        profileHeader.detailContentView = activityControl

        // Attach the Profile Header to the Table View
        tableView.tableHeaderView = profileHeader
    }

    /*
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

         // Configure the cell...

         return cell
     }
     */

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

// MARK: - FUIChartViewDataSource

extension CustomerDetailTableViewController: FUIChartViewDataSource {
    // Return the number of series. Use the previously created seriesData property to do so. If the count of the seriesData is 0 return 0
    func numberOfSeries(in _: FUIChartView) -> Int {
        return seriesData?.count ?? 0
    }

    // Return the number of values the Chart should display. Because this is a two dimensional array, access the count of values in that series using the seriesIndex. Return 0 if the count is 0.
    func chartView(_: FUIChartView, numberOfValuesInSeries seriesIndex: Int) -> Int {
        return seriesData?[seriesIndex].count ?? 0
    }

    // Get the actual value to be displayed. Again this is a two dimensional array so first retrieve the series and with help of the categoryIndex retrieve the value.
    func chartView(_: FUIChartView, valueForSeries seriesIndex: Int, category categoryIndex: Int, dimension _: Int) -> Double? {
        return seriesData?[seriesIndex][categoryIndex]
    }

    // Return the category title with help of the category index.
    func chartView(_: FUIChartView, titleForCategory categoryIndex: Int, inSeries _: Int) -> String? {
        return chartData.categories[categoryIndex]
    }

    // Return the formatted String value for each double value.
    func chartView(_: FUIChartView, formattedStringForValue value: Double, axis _: FUIChartAxisId) -> String? {
        return "\(Int(value))"
    }
}

// MARK: - FUIChartViewDelegate

extension CustomerDetailTableViewController: FUIChartViewDelegate {
    func chartView(_: FUIChartView, didChangeSelections _: [FUIChartPlotItem]?) {
        logger.debug("Did select FUIChartView!")
    }
}

// MARK: - Activity Control Delegate

extension CustomerDetailTableViewController: FUIActivityControlDelegate {
    func activityControl(_: FUIActivityControl, didSelectActivity activityItem: FUIActivityItem) {
        // Switch over the Activity Item type, create and display an Alert when the user taps those activities. You won't implement phone calls or anything here. This is just to show you the capabilities of this control.
        switch activityItem {
        case FUIActivityItem.phone:
            AlertHelper.displayAlert(with: "Phone Activity tapped", error: nil, viewController: self)
            logger.debug("Phone Activity tapped")
        case FUIActivityItem.message:
            AlertHelper.displayAlert(with: "Message Activity tapped", error: nil, viewController: self)
            logger.debug("Message Activity tapped")
        case FUIActivityItem.email:
            AlertHelper.displayAlert(with: "Phone Activity tapped", error: nil, viewController: self)
            logger.debug("Phone Activity tapped")
        default:
            return
        }
    }
}
