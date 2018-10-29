//
//  CatalogTableViewController.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import UIKit

class CatalogTableViewController: UITableViewController {

    var refreshController = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerRefreshController()
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return ApplicationModelController.sharedInstance.userProfileList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CatalogCell, for: indexPath) as! CatalogTableViewCell
        cell.initialize(model: ApplicationModelController.sharedInstance.userProfileList[indexPath.row])
        return cell
    }
 
    // REGISTERING REFRESH CONTROL
    private func registerRefreshController()
    {
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshController
        } else {
            tableView.addSubview(refreshController)
        }
        refreshController.addTarget(self, action: #selector(refresScroller(_:)), for: .valueChanged)
    }
    @objc private func refresScroller(_ sender: Any) {
        // Fetch Weather Data
        self.tableView.reloadData()
        refreshController.endRefreshing()
    }

}
