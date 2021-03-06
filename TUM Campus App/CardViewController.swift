//
//  ViewController.swift
//  TUM Campus App
//
//  Created by Mathias Quintero on 10/28/15.
//  Copyright © 2015 LS1 TUM. All rights reserved.
//

import Sweeft
import UIKit

class CardViewController: UITableViewController, EditCardsViewControllerDelegate {
    
    @IBOutlet weak var probileButtonItem: UIBarButtonItem!
    
    var manager: TumDataManager?
    var cards: [DataElement] = []
    var nextLecture: CalendarRow?
    var refresh = UIRefreshControl()
    var search: UISearchController?
    var logoView: TUMLogoView?
    
    var binding: ImageViewBinding?
    
    func refresh(_ sender: AnyObject?) {
        manager?.loadCards(skipCache: sender != nil).onResult(in: .main) { data in
            self.nextLecture = data.value?.flatMap({ $0 as? CalendarRow }).first
            self.cards = data.value ?? []
            self.tableView.reloadData()
            self.refresh.endRefreshing()
        }
        if manager?.user?.data == nil || sender != nil {
            manager?.userDataManager.fetch(skipCache: sender != nil).onResult(in: .main) { _ in
                self.updateProfileButton()
            }
        }
    }
    
    func didUpdateCards() {
        refresh(nil)
        tableView.reloadData()
    }
    
    func updateProfileButton() {
        if let data = manager?.user?.data {
            binding = data.avatar.bind(to: probileButtonItem, default: #imageLiteral(resourceName: "contact")) { image in
                
                let squared = image.squared()
                return squared.withRoundedCorners(radius: squared.size.height / 2.0, borderSize: 0.0)
            }
        } else {
            binding = nil
            probileButtonItem.image = #imageLiteral(resourceName: "contact")
        }
    }
    
}

extension CardViewController: DetailViewDelegate {
    
    func dataManager() -> TumDataManager? {
        return manager
    }
    
}

extension CardViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLogo()
        setupTableView()
        setupSearch()
        
        manager = (self.navigationController as? CampusNavigationController)?.manager
        refresh(nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
            self.navigationController?.navigationItem.largeTitleDisplayMode = .never
        }
        
        updateProfileButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if var mvc = segue.destination as? DetailView {
            mvc.delegate = self
        }
        if let navCon = segue.destination as? UINavigationController,
            let mvc = navCon.topViewController as? EditCardsViewController {
            
            mvc.delegate = self
        }

        if let mvc = segue.destination as? CalendarViewController {
            mvc.nextLectureItem = nextLecture
        }
    }
    
    func setupLogo() {
        let bundle = Bundle.main
        let nib = bundle.loadNibNamed("TUMLogoView", owner: nil, options: nil)?.flatMap { $0 as? TUMLogoView }
        guard let view = nib?.first else { return }
        logoView = view
        view.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        view.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.navigationItem.titleView = view
    }
    
    func setupTableView() {
        refresh.addTarget(self, action: #selector(CardViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refresh)
        definesPresentationContext = true
    }
    
    func setupSearch() {
        let storyboard = UIStoryboard(name: "CardView", bundle: nil)
        guard let searchResultsController = storyboard.instantiateViewController(withIdentifier: "SearchResultsController") as? SearchResultsController else {
            fatalError("Unable to instatiate a SearchResultsViewController from the storyboard.")
        }
        searchResultsController.delegate = self
        searchResultsController.navCon = self.navigationController
        search = UISearchController(searchResultsController: searchResultsController)
        search?.searchResultsUpdater = searchResultsController
        search?.searchBar.placeholder = "Search"
        search?.obscuresBackgroundDuringPresentation = true
        search?.hidesNavigationBarDuringPresentation = true
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = search
        } else {
            self.tableView.tableHeaderView = search?.searchBar
        }
    }
}

extension CardViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(cards.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 480
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = cards | indexPath.row ?? EmptyCard()
        let cell = tableView.dequeueReusableCell(withIdentifier: item.getCellIdentifier()) as? CardTableViewCell ?? CardTableViewCell()
        cell.setElement(item)
        cell.selectionStyle = .none
		return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}


