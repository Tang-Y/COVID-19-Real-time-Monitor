//
//  ViewController.swift
//  Assignment2_QingqingWu
//
//  Created by Qingqing Wu on 2021-11-08.
//  Email: wuqin@sheridancollege.ca
//  Description: This is a hybrid app to report the number of COVID-19 confirmed cases in Canada since Jan 31, 2020. When your app is loaded, request a web service to get the JSON data from a remote server asynchronously. Then, when a segmented control or pickerview is selected, display the corresponding the daily/total number of cases and draw a line graph using WKWebView and HTML page. This app is only display provinces of 5 plus the country Canada.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //properties
    let JSON_URL = "http://ejd.songho.ca/ios/covid19.json"
    let SEC_PER_DAY = 60 * 60 * 24
    var dates: [String] = [] // for chart (x-values) and pickerView
    var values: [Int] = [] // for chart (y-values)
    var provinceList = ["Canada", "British Columbia", "Ontario", "Quebec", "Alberta", "Nova Scotia"]
    var province: [Province] = []
    var dateFormatter = DateFormatter()
    var numberFormatter = NumberFormatter()
    var cdate = Date()
    var cprovince = ""
    
    // IBOutlet declaration
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var lableTitle: UILabel!
    @IBOutlet weak var pickerDate: UIPickerView!
    @IBOutlet weak var segmentProvince: UISegmentedControl!
    @IBOutlet weak var labelDaily: UILabel!
    @IBOutlet weak var labelTotal: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // config date format
        // set date format as ISO
        dateFormatter.dateFormat = "yyyy-MM-dd"
        numberFormatter.numberStyle = .currencyAccounting
        numberFormatter.locale = .init(identifier: "en_US_POSIX")
        numberFormatter.currencySymbol = ""
        numberFormatter.maximumFractionDigits = 0
        
        // load JSON remotely
        requestJson(JSON_URL)
        
        // loading HTML locally
        // set delegate for webview
        // when the page is loaded, it triggers webView(didFinish:) delegate func
        webView.navigationDelegate = self
        
        // set who is the delegate
        pickerDate.delegate = self
        pickerDate.dataSource = self
        
        let currProvince = provinceList[segmentProvince.selectedSegmentIndex]
        lableTitle.text = "COVID-19: \(currProvince)"
        
        // load html file locally
        if let url = Bundle.main.url(forResource: "test_chart",
                                     withExtension: "html",
                                     subdirectory: "chart_html")
        {
            webView.loadFileURL(url, allowingReadAccessTo: url)
        }
        else
        {
            // use AlertController
            showAlert(message: "ERROR: Failed to create URL")
        }

    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        // called when webview completes receiving web page
        // == DOMContentLoaded
        print("Page is loaded")
    }
    
    // Delegate
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
    {
        // called when failed to load web page
        showAlert(message: "[ERROR]: \(error.localizedDescription)")
    }
    
    func requestJson(_ urlString: String)
    {
        // create URL instance
        guard let url = URL(string: urlString) else
        {
            // alert to users
            showAlert(message: "Cannot create a URL")
            print("[ERROR] Cannot create a URL")
            return
        }
        
        // URLSession.shared is a singleton session object with no configuration (== default session type)
        let task = URLSession.shared.dataTask(with:url, completionHandler: { data, response, error in
            // check errors
            if let error = error
            {
                self.showAlert(message: error.localizedDescription)
                print("[ERROR] " + error.localizedDescription)
                return
            }
            guard let data = data else
            {
                self.showAlert(message: "Data is nil.")
                print("[ERROR] Data is nil")
                return
            }
    
            // parse json as an array of students using JSONSerialization
            self.parseJson(data)
        })
        
        // must call resume() after creating dataTask
        task.resume()
    }
    
     func parseJson(_ data: Data)
     {
            showAlert(title: "ParseJSON", message: "Going to parse JSON")
            
            // parse json as an array [Any] using JSONSerialization
            do
            {
                // convert root node of json to array of dictionaries
                let decoder = JSONDecoder()
                let json = try decoder.decode([Province].self, from: data)
                self.province = json // remember the JSON data
                
                // generate “dates” array for UIpickerView
                // compute # of dates to set the array size of values
                let firstDate = self.dateFormatter.date(from: self.province[0].date) ?? Date()
                let lastDate = self.dateFormatter.date(from: self.province[self.province.count - 1].date) ?? Date()
                
                let sec = lastDate.timeIntervalSince(firstDate)
                let dateCount = Int(sec / Double(SEC_PER_DAY) + 0.5) + 1
                
                // resize arrays
                self.dates = [String](repeating: "", count: dateCount)
                
                // construct dates array
                for i in 0 ..< dateCount {
                    let date = firstDate + (Double(i) * Double(SEC_PER_DAY)) // increment by 1-day
                    self.dates[i] = dateFormatter.string(from: date) // to ISO format
                }
                
                // do other parsing process if neccessory
                    
                // parsing is done, update UIs in main thread
                DispatchQueue.main.async
                {
                    // reload pickerview
                    self.pickerDate.reloadAllComponents()
                    // select the latest date by default
                    self.pickerDate.selectRow(self.dates.count-1,
                    inComponent: 0, animated: false)
                    
                    // draw the line graph
                    // the page is loaded, draw chart first time here
                    self.initialLoad(selectedSegmentIndex: 0)
                }
                        
                if let json = try JSONSerialization.jsonObject(with:data, options:[]) as? [[String:Any]]
                {
                    for dict in json
                    {
                        // convert each element to dictionary [String:Any]
                        if let dict = data as? [String : Any]
                        {
                        var province = Province()
                        province.provinceName = dict["prname"] as? String ?? ""
                        province.date = dict["date"] as? String ?? ""
                        province.numberTotal = dict["numtotal"] as? Int ?? 0
                        province.numberToday = dict["numtoday"] as? Int ?? 0

                        // Add to the province dataset class
                        self.province.append(province)
                        }
                    }
                }
            }
            //catch let error as NSError
            catch
            {
                // alert to users
                showAlert(message: "Failed to request data")
                print("[ERROR] " + error.localizedDescription)
                return
            }
     }
    

    // load first when page is load
    func initialLoad(selectedSegmentIndex: Int)
    {
        // get selected province name
        let currProvince = self.provinceList[selectedSegmentIndex]
        let firstDate = self.dateFormatter.date(from: self.province[selectedSegmentIndex].date) ?? Date()

        // update title text and store the current province in a temp variable
        lableTitle.text = "COVID-19: \(currProvince)"
        cprovince = currProvince

        // You need to define it by yourself to update labels
        self.updateLabels(currDate: cdate)

        // generate array to pass to JS
        var values = [Int](repeating: 0, count: dates.count) // same size as “dates”
        for covid in self.province
        {
            // if selected province is same, put its number to array
            if covid.provinceName == currProvince
            {
                // compute index using timeIntervalSince()
                let date = dateFormatter.date(from: covid.date) ?? Date()
                let sec = date.timeIntervalSince(firstDate) // sec since the first
                let index = Int(sec / Double(SEC_PER_DAY) + 0.5)
                values[index] = covid.numberToday
            }
        }

        // 4. Pass data to JS (see TestWebKitChart example for detail)
        var dict: [String:Any] = [:]
        dict["xs"] = self.dates
        dict["ys"] = values

        let json = toJsonString(from: dict)
        let js = "drawChart(\(json))"
        self.webView.evaluateJavaScript(js)
        
        // first load to select the latest row in order to load info
        pickerDate.selectRow(dates.count-1, inComponent: 0, animated: true)
        pickerView(pickerDate, didSelectRow:dates.count-1 , inComponent: 0)
    }
    
    // segement control
    @IBAction func changeProvince(_ sender: UISegmentedControl)
    {
        // get selected province name
        let currProvince = self.provinceList[sender.selectedSegmentIndex]
        let firstDate = self.dateFormatter.date(from: self.province[sender.selectedSegmentIndex].date) ?? Date()
        
        lableTitle.text = "COVID-19: \(currProvince)"
        cprovince = currProvince
        
        //You need to define it by yourself to update labels
        self.updateLabels(currDate: cdate)

        // generate array to pass to JS
        var values = [Int](repeating: 0, count: dates.count) // same size as “dates”
        for covid in self.province
        {
            // if selected province is same, put its number to array
            if covid.provinceName == currProvince
            {
                // compute index using timeIntervalSince()
                let date = dateFormatter.date(from: covid.date) ?? Date()
                let sec = date.timeIntervalSince(firstDate) // sec since the first
                let index = Int(sec / Double(SEC_PER_DAY) + 0.5)
                values[index] = covid.numberToday
            }
        }
        
        // 4. Pass data to JS (see TestWebKitChart example for detail)
        var dict: [String:Any] = [:]
        dict["xs"] = self.dates
        dict["ys"] = values
        
        let json = toJsonString(from: dict)
        let js = "drawChart(\(json))"
        self.webView.evaluateJavaScript(js)
    }
    
    // update labels upon user selecting
    func updateLabels(currDate: Date){
        for covid in self.province
        {
            // if selected province is same, put its number to array
            if covid.provinceName == cprovince
            {
                let date = dateFormatter.date(from: covid.date) ?? Date()
                if date == currDate {
                    labelDaily.text = numberFormatter.string(from: NSNumber(value: covid.numberToday))
                    labelTotal.text = numberFormatter.string(from: NSNumber(value: covid.numberTotal))
                }
            }
        }
    }
    
    // generate the date picker view
    // delegate functions for pickerview
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        dates.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dates[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    
        // get the title of selected row
        let date = self.pickerView(pickerView, titleForRow: row, forComponent: 0) ?? ""
        cdate = self.dateFormatter.date(from: date) ?? Date()
        
        updateLabels(currDate: cdate)
    }
    
    func toJsonString(from: Any) -> String
    {
        // NOTE: you may use JSONEncoder instead,
        // but the object must conform Encodable protocol
        if let data = try? JSONSerialization.data(withJSONObject: from,
                                                  options: []),
           let jsonString = String(data: data, encoding: .utf8)
        {
            return jsonString
        }
        else
        {
            // failed to encode, return empty object
            return "{}"
        }
    }
    

    func showAlert(title:String = "Error", message:String)
    {
        DispatchQueue.main.async
        {
            // create alert controller
            let alert = UIAlertController(title:title, message:message, preferredStyle:.alert)

            // add default button
            alert.addAction(UIAlertAction(title:"OK", style:.default, handler:nil))

            // show it
            self.present(alert, animated:true, completion:nil)
        }
    }
}


