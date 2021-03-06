//
//  ViewController.swift
//  desafio-ios
//
//  Created by Alexandre Scheer Bing on 05/12/20.
//

import UIKit
import RxSwift
import RxCocoa

class StatementViewController: UIViewController {
    
    static let startLoadingOffset: CGFloat = 20.0

    static func isNearTheBottomEdge(contentOffset: CGPoint, _ tableView: UITableView) -> Bool {
        return contentOffset.y + tableView.frame.size.height + startLoadingOffset > tableView.contentSize.height
    }
    
    @IBOutlet weak var showExtractButton: UIButton!
    @IBOutlet weak var extractLabel: UILabel!
    
    @IBOutlet weak var transferStatementTableView: UITableView!
    
    @IBOutlet weak var hideExtractView: UIView!
    @IBOutlet weak var extractSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var tableViewSpinner: UIActivityIndicatorView!
    
    let disposeBag = DisposeBag()
    private var viewModel: StatementViewModel!
    var coordinator: MainCoordinator?
    var showExtract: Bool = false
    
    static func instantiate(with viewModel: StatementViewModel) -> StatementViewController {
        let storyboard = UIStoryboard(name: "StatementView", bundle: .main)
        guard let viewController = storyboard.instantiateInitialViewController() as? StatementViewController else { return StatementViewController()}
        viewController.viewModel = viewModel
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupExtract()
        setupTableView()
    }
    
    private func setupNavBar() {
        navigationItem.title = "Extrato"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    private func setupExtract(){
        if let previousShowExtractStatus = UserDefaults.standard.value(forKey: "showExtract") as? Bool {
            showExtract = previousShowExtractStatus
        }
        setExtractButtonImage(for: showExtract)
        if showExtract {
            loadAmount()
        } else {
            hideExtractView.alpha = 1
            extractLabel.alpha = 0
        }
        
    }
    
    private func loadAmount(){
        extractLabel.alpha = 0
        extractSpinner.startAnimating()
        viewModel.fetchAmmount().observe(on: MainScheduler.instance)
            .catch({ error -> Observable<String> in
                print(error)
                return .just("Um erro ocorreu, tente novamente mais tarde")
            })
            .bind(onNext: { [self] result in
                extractLabel.text = result
                extractSpinner.stopAnimating()
                UIView.animate(withDuration: 0.5){
                    extractLabel.alpha = 1
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupTableView(){
        transferStatementTableView.tableFooterView = UIView()
        transferStatementTableView.contentInsetAdjustmentBehavior = .never
        
        UIView.transition(with: transferStatementTableView, duration: 5.0, options: .curveEaseInOut, animations: {self.transferStatementTableView.reloadData()}, completion: nil)
        
        viewModel.setTableRowHeight()
            .observe(on: MainScheduler.instance)
            .bind(to: transferStatementTableView.rx.rowHeight)
            .disposed(by: disposeBag)
        
        viewModel.fetchStatement(offset: 0)
            .observe(on: MainScheduler.instance)
            .catch { error -> Observable<[Statement]> in
                print(error)
                return .just([])
            }
            .bind(to: transferStatementTableView.rx.items){ [self] (tableView, row, item) -> UITableViewCell in
                self.tableViewSpinner.stopAnimating()
                let cell = transferStatementTableView.dequeueReusableCell(withIdentifier: "StatementCell") as! StatementTableViewCell
                cell.setData(transferenceType: item.transferenceType, subject: ((item.to ?? item.from) ?? item.bankName) ?? "Sem informação", value: item.amountString, date: item.createdAt)
                cell.alpha = 0
                UIView.animate(withDuration: 0.5) {
                    cell.alpha = 1
                }
                return cell
            }
            .disposed(by: disposeBag)
        
        transferStatementTableView.rx
            .modelSelected(Statement.self)
            .subscribe(onNext: { [self] value in
                coordinator?.goToDetail(with: value.id)
            }).disposed(by: disposeBag)
        
        transferStatementTableView.rx.contentOffset.subscribe{
            guard let offset = $0.element?.y else { return }
            if offset > 106{
                print("offset now \(offset)")
            }
            
        }.disposed(by: disposeBag)
    }
    
    private func setExtractButtonImage(for showExtract: Bool) {
        if showExtract {
            showExtractButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            showExtractButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }
    
    @IBAction func toggleExtractView(_ sender: Any) {
        showExtract.toggle()
        setExtractButtonImage(for: showExtract)
        if showExtract {
            UIView.animate(withDuration: 0.2) {
                self.hideExtractView.alpha = 0
                self.loadAmount()
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.hideExtractView.alpha = 1
                self.extractLabel.alpha = 0
            }
        }
        UserDefaults.standard.setValue(showExtract, forKey: "showExtract")
        
    }
}

