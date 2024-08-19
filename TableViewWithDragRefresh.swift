//
//  TableViewWithDragRefresh.swift
//  SwiftCodeSnippets
//
//  Created by Minyoung Yoo on 8/20/24.
//

import UIKit
import Combine

struct ProviderPost: Codable, Identifiable {
    let id: Int
    let enabled: Int
    let createDate: String
    let updateDate: String
    let ownerId: String
    let sitterId: String
    let ownerNickname: String
    let sitterNickname: String
}

class ExampleViewModel {
    @Published var postData: [ProviderPost] = []
    
    func fetchPostData() async throws {
        let endpoint = "http://localhost:8000/api/test"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let jsonData = try JSONDecoder().decode([ProviderPost].self, from: data)
        self.postData = jsonData
    }
}

class ExampleViewController: UIViewController {
    
    let viewModel: ExampleViewModel = ExampleViewModel()
    var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    let tableView: UITableView = {
        let tb = UITableView()
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.setupTableView()
        self.setupView()
        self.configureRefreshTableDataControl()
        self.bind()
    }
    
    private func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(CustomTableCell.self, forCellReuseIdentifier: "tableData")
        
        Task {
            do {
                try await self.viewModel.fetchPostData()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func setupView() {
        //setup safearea
        let safeArea = self.view.safeAreaLayoutGuide
        self.view.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
        ])
    }
    
    private func configureRefreshTableDataControl() {
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.addAction(UIAction { [weak self] action in
            Task {
                do {
                    try await self?.viewModel.fetchPostData()
                } catch {
                    print(error.localizedDescription)
                }
                self?.tableView.refreshControl?.endRefreshing()
            }
        }, for: .valueChanged)
    }
    
    private func bind() {
        self.viewModel.$postData.receive(on: DispatchQueue.main).sink { completion in
            print(completion)
        } receiveValue: { [weak self] data in
            self?.tableView.reloadData()
        }
        .store(in: &cancellables)
    }
}

extension ExampleViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount: Int = self.viewModel.postData.count
        print(rowCount)
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = CustomTableCell(enabled: self.viewModel.postData[indexPath.row].enabled,
                                   ownerNickname: self.viewModel.postData[indexPath.row].ownerNickname,
                                   sitterNickname: self.viewModel.postData[indexPath.row].sitterNickname,
                                   identifier: "tableData")
        cell.enabled = self.viewModel.postData[indexPath.row].enabled
        cell.ownerNickname = self.viewModel.postData[indexPath.row].ownerNickname
        cell.sitterNickname = self.viewModel.postData[indexPath.row].sitterNickname
        return cell
    }
    
}

class CustomTableCell: UITableViewCell {
    var enabled: Int
    var ownerNickname: String
    var sitterNickname: String
    
    init(enabled: Int, ownerNickname: String, sitterNickname: String, identifier: String) {
        self.enabled = enabled
        self.ownerNickname = ownerNickname
        self.sitterNickname = sitterNickname
        super.init(style: .default, reuseIdentifier: identifier)
        
        setCellContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCellContent() {
        let descriptionLabel = UILabel()
        let titleLabel = UILabel()
        titleLabel.text = self.ownerNickname
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = self.sitterNickname
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(descriptionLabel)
        self.contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.bottomAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            
            descriptionLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
}
