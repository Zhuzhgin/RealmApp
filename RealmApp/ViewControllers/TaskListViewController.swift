//
//  TaskListsViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

class TaskListViewController: UITableViewController {

    
    @IBOutlet weak var sortBySegmentControl: UISegmentedControl!
    
    var taskLists: Results<TaskList>!
    var taskListsSortedByTitle: Results<TaskList>!
    var taskListsSortedByDate: Results<TaskList>!
    var taskListsUnsorted: Results<TaskList>!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskListsUnsorted = StorageManager.shared.realm.objects(TaskList.self)
        
        if sortBySegmentControl.selectedSegmentIndex == 0 {
        taskListsSortedByDate = taskListsUnsorted.sorted(byKeyPath: "date", ascending: true)
            taskLists = taskListsSortedByDate
        } else {
            taskListsSortedByTitle = taskListsUnsorted.sorted(byKeyPath: "name", ascending: true)
            taskLists = taskListsSortedByTitle
        }
 
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = editButtonItem
        
        createTempData()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let taskList = taskLists[indexPath.row]
    
        content.text = taskList.name
        
        let currentTasks = taskList.tasks.filter("isComplete = false")
        let completedTasks = taskList.tasks.filter("isComplete = true")
        
        if currentTasks.count == 0 && completedTasks.count != 0 {
            content.secondaryText = "Done"
        } else if currentTasks.count == 0 && completedTasks.count == 0 {
            content.secondaryText = ""
        } else {
            content.secondaryText = "\(currentTasks.count)"
        }
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: taskList) {
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
            StorageManager.shared.done(taskList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
    }

    @IBAction func sortingList(_ sender: UISegmentedControl) {
    }
    
    @objc private func  addButtonPressed() {
        showAlert()
    }
    
    private func createTempData() {
        DataManager.shared.createTempDataV2 {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func sortByChoice(_ sender: UISegmentedControl) {
        
        switch sortBySegmentControl.selectedSegmentIndex{
        case 0:
            
            taskListsSortedByDate = taskListsUnsorted.sorted(byKeyPath: "date", ascending: true)
            taskLists = taskListsSortedByDate
            tableView.reloadData()
        case 1:
            taskListsSortedByTitle = taskListsUnsorted.sorted(byKeyPath: "name", ascending: true)
            taskLists = taskListsSortedByTitle
            tableView.reloadData()
        default:
            return
        }
        }
}

extension TaskListViewController {
    
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let title = taskList != nil ? "Edit List" : "New List"
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "Please set title for new task list")
        
        alert.action(with: taskList) { newValue in
            if let taskList = taskList, let completion = completion {
                StorageManager.shared.edit(taskList, newValue: newValue)
                completion()
            } else {
                self.save(taskList: newValue)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(taskList: String) {
        let taskList = TaskList(value: [taskList])
        StorageManager.shared.save(taskList)
        
        let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
}
