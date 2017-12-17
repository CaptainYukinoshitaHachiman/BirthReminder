//
//  AnimeGettingFromServerViewController.swift
//  BirthdayReminder
//
//  Created by Jacky Yu on 17/07/2017.
//  Copyright © 2017 CaptainYukinoshitaHachiman. All rights reserved.
//

import UIKit
import SnapKit
import ObjectMapper
import ViewAnimator
import CFNotify
import NVActivityIndicatorView

class AnimeGettingFromServerViewController: ViewController {
    
    private var requirements: String?
    
    private var animes = [Anime]() {
        didSet {
            loadPicsForAnimes()
        }
    }
    private var allAnimes = [Anime]()
    
    private var activityIndicator = NVActivityIndicatorView(frame: CGRect(origin: .zero, size: CGSize(width: 150, height: 150)), type: .orbit, color: .cell, padding: nil)
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background
        
        // Agreement
        let defaults = UserDefaults()
        if !defaults.bool(forKey: "shouldHideAgreement") {
            let cfView = CFNotifyView.cyberWith(title: NSLocalizedString("about", comment: "about"), body: NSLocalizedString("agreement", comment: "The infomation and pictures are collected from the Internet, and they don't belong to the app's developer.\nPlease email me if you think things here are infringing your right, and I'll remove them. (You may see my contact info in the App Store Page, or the about page from index)"), theme: .warning(.light))
            var config = CFNotify.Config()
            config.initPosition = .top(.center)
            config.appearPosition = .top
            config.hideTime = .never
            CFNotify.present(config: config, view: cfView)
            
            defaults.set(true, forKey: "shouldHideAgreement")
        }
        
        tableView.backgroundView?.backgroundColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        
        tableView.separatorStyle = .none
        
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints() { make in
            make.center.equalToSuperview()
        }
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.tintColor = .white
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        loadAnimes()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAnimeDetail" {
            let viewController = segue.destination as! GetPersonalDataFromServerViewController
            viewController.anime = sender as? Anime
            viewController.navigationItem.title = (sender as! Anime).name.replacingOccurrences(of: "\n", with: "")
        }
    }
    
    func loadAnimes() {
        activityIndicator.stopAnimating()
        if let requirement = requirements, requirement != ""  {
            animes = []
            tableView.reloadData()
        } else {
            animes = allAnimes
            tableView.reloadData()
            if !animes.isEmpty { return }
        }
        activityIndicator.startAnimating()
        NetworkController.provider.request(.animes(requirements: requirements)) { [weak self] response in
            switch response {
            case .success(let result):
                let json = String(data: result.data, encoding: String.Encoding.utf8)!
                self?.animes = Mapper<Anime>().mapArray(JSONString: json)!
                if self?.requirements == nil || self?.requirements == "" {
                    self?.allAnimes = self?.animes ?? []
                }
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.tableView.reloadData()
                    self?.tableView.animate(animations: [AnimationType.from(direction: .bottom, offset: 40)])
                }
            case .failure(let error):
                self?.animes = []
                DispatchQueue.main.async {
                    let cfView = CFNotifyView.cyberWith(title: NSLocalizedString("failedToLoad", comment: "FailedToLoad"), body: error.localizedDescription, theme: .fail(.light))
                    var config = CFNotify.Config()
                    config.initPosition = .top(.center)
                    config.appearPosition = .top
                    CFNotify.present(config: config, view: cfView)
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func loadPicsForAnimes() {
        animes.forEach { anime in
            NetworkController.provider.request(.animepic(withID: anime.id)) { [weak self] response in
                switch response {
                case .success(let result):
                    let data = result.data
                    anime.pic = UIImage(data: data)
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error.errorDescription!)
                }
            }
        }
    }
    
}

extension AnimeGettingFromServerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        performSegue(withIdentifier: "showAnimeDetail", sender: animes[index])
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "animeCell") as! AnimeCell
        if let image = animes[index].pic {
            cell.picView?.image = image
        }
        cell.nameLabel.text = animes[index].name
        return cell
    }
    
}

extension AnimeGettingFromServerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        requirements = searchController.searchBar.text
        loadAnimes()
    }
}
