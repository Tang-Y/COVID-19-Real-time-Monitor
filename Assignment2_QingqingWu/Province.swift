//
//  Province.swift
//  Assignment2_QingqingWu
//
//  Created by Qingqing Wu on 2021-11-18.
//  Email: wuqin@sheridancollege.ca
//  Description: This is the codable data class to store dataset using codingKey and value set. the data retrieved from json file will be stored locally in this class
//

import Foundation

struct Province: Codable
{
    var provinceName = ""
    var date = ""
    var numberTotal = 0
    var numberToday = 0
    
    
    enum CodingKeys: String, CodingKey
    {
        case provinceName = "prname"
        case date = "date"
        case numberTotal = "numtotal"
        case numberToday = "numtoday"
    }
}
