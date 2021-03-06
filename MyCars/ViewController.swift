//
//  ViewController.swift
//  MyCars
//
//  Created by Ivan Akulov on 08/02/20.
//  Copyright © 2020 Ivan Akulov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var car: Car!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            updateSegmentedControl()
            segmentedControl.selectedSegmentTintColor = .white
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
        }
    }
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentedControl()
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print (error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate it", message: "Rate this car!", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alertController.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func updateSegmentedControl () {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        guard let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) else { return }
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark)
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print (error.localizedDescription)
        }
    }
    
    private func update(rating: Double) {
        car.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            
            alertController.addAction(okAction)
            present(alertController, animated: true)
            print (error.localizedDescription)
        }
        
    }
    
    private func insertDataFrom(selectedCar car: Car) {
        guard let data = car.imageData else { return }
        carImageView.image = UIImage(data: data)
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        guard let time = car.lastStarted else { return }
        lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: time))"
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    private func getDataFromFile() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        do {
            records = try context.count(for: fetchRequest)
            print ("Is data there already")
        } catch let error as NSError {
            print (error.localizedDescription)
        }
        
        guard records == 0 else { return }
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
              let dataArray = NSArray(contentsOfFile: pathToFile) else { return }
        
        for dictionary in dataArray {
            guard let entity = NSEntityDescription.entity(forEntityName: "Car", in: context) else { return }
            let car = NSManagedObject(entity: entity, insertInto: context) as? Car
            
            let carDictionary = dictionary as! [String : AnyObject]
            car?.mark = carDictionary["mark"] as? String
            car?.model = carDictionary["model"] as? String
            car?.rating = carDictionary["rating"] as? Double ?? 0
            car?.lastStarted = carDictionary["lastStarted"] as? Date
            car?.timesDriven = carDictionary["timesDriven"] as? Int16 ?? 0
            car?.myChoice = carDictionary["myChoice"] as? Bool ?? false
            
            let imageName = carDictionary["imageName"] as? String
            let image = UIImage(named: imageName ?? "")
            let imageData = image?.pngData()
            car?.imageData = imageData
            
            if let colourDictionary = carDictionary["tintColor"] as? [String : Float] {
                car?.tintColor = getColor(colourDictionary: colourDictionary)
            }
        }
                
    }
    
    private func getColor(colourDictionary: [String: Float]) -> UIColor {
        guard let red = colourDictionary["red"],
              let green = colourDictionary["green"],
              let blue = colourDictionary["blue"] else { return UIColor()}
        return UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1.0)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDataFromFile()
        
    }
    
}

