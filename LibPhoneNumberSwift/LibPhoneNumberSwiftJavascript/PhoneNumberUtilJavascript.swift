
//  PhoneNumberUtilJavascript.swift
//  LibPhoneNumberSwift
//
//  Created by Hyuk Hur on 1/1/15.
//  Copyright (c) 2015 Hyuk Hur. All rights reserved.
//

/* http://closure-compiler.appspot.com */
// ==ClosureCompiler==
// @compilation_level SIMPLE_OPTIMIZATIONS
// @use_closure_library true
// @code_url https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/phonemetadata.pb.js
// @code_url https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/phonenumber.pb.js
// @code_url https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/metadata.js
// @code_url https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/phonenumberutil.js
// @code_url https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/asyoutypeformatter.js
// ==/ClosureCompiler==


import Foundation
import LibPhoneNumberSwift
import JavaScriptCore

protocol JavascriptString {
    func toJavascript(#lineNumber:Int) -> (variableName:String, javascript:String)
}

extension JSContext {
    func invokeMethodWithNew(functionName:String, args:[AnyObject], lineNumber:Int = __LINE__) -> (value:JSValue?, arguments:[String]) {
        var create = ""
        let arguments = args.map({(arg:AnyObject) -> String in
            if let nextJavascript = arg as? JavascriptString {
                let javascript = nextJavascript.toJavascript(lineNumber:lineNumber)
                create += javascript.javascript
                return javascript.variableName
            } else if let next = arg as? Bool {
                return next ? "true" : "false"
            } else if let name:String = arg as? String where name.hasSuffix("StringBuffer") {
                create += "var \(name) = new goog.string.StringBuffer();"
                return name
            }
            return arg.description
        })
        let argumentsString = join(", ", arguments)
        let evaluatingJavascript = create + "phoneUtil.\(functionName)(\(argumentsString));"
        print(evaluatingJavascript)
        return (self.evaluateScript(evaluatingJavascript), arguments)
    }
}

var callCount:Int = 0
extension NumberFormat:JavascriptString {
    convenience init(javascriptValue:JSValue) {
        self.init()
        if let value = javascriptValue.invokeMethod("getPattern", withArguments: nil).toString() where value != "undefined"  {
            self.pattern = value
        }
        if let value = javascriptValue.invokeMethod("getFormat", withArguments: nil).toString() where value != "undefined"  {
            self.format = value
        }
        if let value:[String] = javascriptValue.invokeMethod("leadingDigitsPatternArray", withArguments: nil).toArray() as? [String] {
            for pattern in value {
                self.leadingDigitsPattern.append(pattern)
            }
        }
        if let value = javascriptValue.invokeMethod("getNationalPrefixFormattingRule", withArguments: nil).toString() where value != "undefined"  {
            self.nationalPrefixFormattingRule = value
        }
    }
    func toJavascript(lineNumber:Int = __LINE__) -> (variableName:String, javascript:String) {
        let varName = "numberFormat_\(lineNumber)_\(callCount++)"
        let pattern = self.pattern.stringByReplacingOccurrencesOfString("\\", withString: "\\\\")
        let format = self.format.stringByReplacingOccurrencesOfString("\\", withString: "\\\\")
        var javascript = " " +
            "var \(varName) = new i18n.phonenumbers.NumberFormat();" +
            "\(varName).setPattern(\"\(pattern)\");" +
            "\(varName).setFormat(\"\(format)\");"

        if self.leadingDigitsPattern.count > 0 {
            let leadingDigitsPattern = self.leadingDigitsPattern.reduce("[", combine: { (string:String, format:String) -> String in
                return "\(string) \"\(format)\","
            }) + "]"
            javascript += "\(varName).setLeadingDigitsPatternArray(\(leadingDigitsPattern));"
        }
        if self.nationalPrefixFormattingRule != "" {
            javascript += "\(varName).setNationalPrefixFormattingRule(\"\(self.nationalPrefixFormattingRule)\");"
        }
        return (varName, javascript)
    }
}

extension PhoneNumber:JavascriptString {
    convenience init(javascriptValue:JSValue) {
        self.init()
        if let value = javascriptValue.invokeMethod("getCountryCode", withArguments: nil) where value.isNumber()  {
            self.countryCode = value.toNumber().integerValue
        }
        if let value = javascriptValue.invokeMethod("getNationalNumber", withArguments: nil) where value.isNumber()  {
            self.nationalNumber = value.toNumber().integerValue
        }
        if let value = javascriptValue.invokeMethod("getExtension", withArguments: nil) where value.isString()  {
            self.extensionFormat = value.toString()
        }
        if let value = javascriptValue.invokeMethod("getItalianLeadingZero", withArguments: nil) where value.isBoolean()  {
            self.isItalianLeadingZero = value.toBool()
        }
        if let value = javascriptValue.invokeMethod("getNumberOfLeadingZeros", withArguments: nil) where value.isNumber()  {
            self.numberOfLeadingZeros = value.toNumber().integerValue
        }
        if let value = javascriptValue.invokeMethod("getRawInput", withArguments: nil) where value.isString()  {
            self.rawInput = value.toString()
        }
        if let value = javascriptValue.invokeMethod("getCountryCodeSource", withArguments: nil) where value.isNumber()  {
            self.countryCodeSource = CountryCodeSource(rawValue:value.toNumber().integerValue)
        }
        if let value = javascriptValue.invokeMethod("getPreferredDomesticCarrierCode", withArguments: nil) where value.isString()  {
            if value.toString() != "" {
                self.preferredDomesticCarrierCode = value.toString()
            }
        }
    }
    func toJavascript(lineNumber:Int = __LINE__) -> (variableName:String, javascript:String) {
        let varName = "phoneNumber_\(lineNumber)_\(callCount++)"
        var javascript = " " +
            "var \(varName) = new i18n.phonenumbers.PhoneNumber();" +
            "\(varName).setCountryCode(\(self.countryCode));" +
        "\(varName).setNationalNumber(\(self.nationalNumber));"

        if self.isItalianLeadingZero {
            javascript += "\(varName).setItalianLeadingZero(\(self.isItalianLeadingZero));"
        }
        if let countryCodeSource = self.countryCodeSource {
            javascript += "\(varName).setCountryCodeSource(\(countryCodeSource.rawValue));"
        }
        if self.rawInput != "" {
            javascript += "\(varName).setRawInput(\"\(self.rawInput)\");"
        }
        if self.extensionFormat != "" {
            javascript += "\(varName).setExtension(\"\(self.extensionFormat)\");"
        }
        if self.numberOfLeadingZeros != 1 {
            javascript += "\(varName).setNumberOfLeadingZeros(\(self.numberOfLeadingZeros));"
        }
        if let preferredDomesticCarrierCode = self.preferredDomesticCarrierCode {
            javascript += "\(varName).setPreferredDomesticCarrierCode(\"\(preferredDomesticCarrierCode)\");"
        }
        return (varName, javascript)
    }
}

extension PhoneNumberDesc:JavascriptString {
    convenience init(javascriptValue:JSValue) {
        self.init()
        if let value:JSValue = javascriptValue.invokeMethod("getNationalNumberPattern", withArguments: nil) where value.isString()  {
            self.nationalNumberPattern = value.toString()
        }
        if let value = javascriptValue.invokeMethod("getPossibleNumberPattern", withArguments: nil) where value.isString() {
            self.possibleNumberPattern = value.toString()
        }
        if let value = javascriptValue.invokeMethod("getExampleNumber", withArguments: nil) where value.isString() {
            self.exampleNumber = value.toString()
        }
    }
    func toJavascript(lineNumber:Int = __LINE__) -> (variableName: String, javascript: String) {
        let varName = "phoneNumberDesc_\(lineNumber)_\(callCount++)"
        var javascript = "var \(varName) = new i18n.phonenumbers.PhoneNumberDesc();"
        javascript += "\(varName).setNationalNumberPattern(\"\(self.nationalNumberPattern)\");"
        javascript += "\(varName).setPossibleNumberPattern(\"\(self.possibleNumberPattern)\");"
        javascript += "\(varName).setExampleNumber(\"\(self.exampleNumber)\");"
        return (varName, javascript)
    }
}

extension PhoneMetadata:JavascriptString {
    convenience init(javascriptValue:JSValue) {
        self.init()
        if let value = javascriptValue.invokeMethod("getId", withArguments: nil).toString() where value != "undefined" {
            self.metadataID = value
        }
        if let value = javascriptValue.invokeMethod("getCountryCode", withArguments: nil).toNumber() where !isnan(value.doubleValue) {
            self.countryCode = value.integerValue
        }
        if let value = javascriptValue.invokeMethod("getInternationalPrefix", withArguments: nil).toString() where value != "undefined" {
            self.internationalPrefix = value
        }
        if let value = javascriptValue.invokeMethod("getNationalPrefix", withArguments: nil).toString() where value != "undefined" {
            self.nationalPrefix = value
        }
        if let value = javascriptValue.invokeMethod("getNationalPrefixForParsing", withArguments: nil).toString() where value != "undefined" {
            self.nationalPrefixForParsing = value
        }
        if let value = javascriptValue.invokeMethod("getNationalPrefixTransformRule", withArguments: nil).toString() where value != "undefined" {
            self.nationalPrefixTransformRule = value
        }
        if let value = javascriptValue.invokeMethod("numberFormatArray", withArguments: nil) {
            var format = value.invokeMethod("shift", withArguments:nil)
            while format.toString() != "undefined" {
                self.numberFormats.append(NumberFormat(javascriptValue:format))
                format = value.invokeMethod("shift", withArguments:nil)
            }
        }
        if let value = javascriptValue.invokeMethod("intlNumberFormatArray", withArguments: nil) {
            var format = value.invokeMethod("shift", withArguments:nil)
            while format.toString() != "undefined" {
                self.intlNumberFormats.append(NumberFormat(javascriptValue:format))
                format = value.invokeMethod("shift", withArguments:nil)
            }
        }
        if let value = javascriptValue.invokeMethod("getGeneralDesc", withArguments: nil) {
            self.generalDesc = PhoneNumberDesc(javascriptValue:value)
        }
        if let value = javascriptValue.invokeMethod("getTollFree", withArguments: nil) {
            self.tollFree = PhoneNumberDesc(javascriptValue:value)
        }
        if let value = javascriptValue.invokeMethod("getFixedLine", withArguments: nil) {
            self.fixedLine = PhoneNumberDesc(javascriptValue:value)
        }
        if let value = javascriptValue.invokeMethod("getPremiumRate", withArguments: nil) {
            self.premiumRate = PhoneNumberDesc(javascriptValue:value)
        }
        if let value = javascriptValue.invokeMethod("getSharedCost", withArguments: nil) {
            self.sharedCost = PhoneNumberDesc(javascriptValue:value)
        }
    }
    func toJavascript(lineNumber:Int = __LINE__) -> (variableName:String, javascript:String) {
        let varName = "phoneMetadata_\(lineNumber)_\(callCount++)"
        var javascript = " " +
            "var \(varName) = new i18n.phonenumbers.PhoneMetadata();" +
            "\(varName).setNationalPrefixForParsing(\"\(self.nationalPrefixForParsing)\");"

//        if self.metadataID != "" {
            javascript += "\(varName).setId(\"\(self.metadataID)\");"
//        }
        javascript += "\(varName).setCountryCode(\(countryCode));"
//        if self.internationalPrefix != "" {
            javascript += "\(varName).setInternationalPrefix(\"\(self.internationalPrefix)\");"
//        }
//        if self.nationalPrefix != "" {
            javascript += "\(varName).setNationalPrefix(\"\(self.nationalPrefix)\");"
//        }
//        if self.nationalPrefixTransformRule != "" {
            javascript += "\(varName).setNationalPrefixTransformRule(\"\(self.nationalPrefixTransformRule)\");"
//        }
        var numberFormats = self.numberFormats
        if numberFormats.count > 0 {
            var numberFormatsObjects = [String]()
            let numberFormats = numberFormats.reduce("", combine: { (string:String, format:NumberFormat) -> String in
                let js = format.toJavascript()
                numberFormatsObjects.append(js.variableName)
                return string + js.javascript
            })
            javascript += numberFormats
            javascript += join("", numberFormatsObjects.map({
                return "\(varName).addNumberFormat(\($0));"
            }))
        }
        numberFormats = self.intlNumberFormats
        if numberFormats.count > 0 {
            var numberFormatsObjects = [String]()
            let numberFormats = numberFormats.reduce("", combine: { (string:String, format:NumberFormat) -> String in
                let js = format.toJavascript()
                numberFormatsObjects.append(js.variableName)
                return string + js.javascript
            })
            javascript += numberFormats
            javascript += join("", numberFormatsObjects.map({
                return "\(varName).addIntlNumberFormat(\($0));"
            }))
        }
        let generalDesc = self.generalDesc.toJavascript()
        javascript += generalDesc.javascript
        javascript += "\(varName).setGeneralDesc(\(generalDesc.variableName));"

        let tollFree = self.tollFree.toJavascript()
        javascript += tollFree.javascript
        javascript += "\(varName).setTollFree(\(tollFree.variableName));"

        let fixedLine = self.fixedLine.toJavascript()
        javascript += fixedLine.javascript
        javascript += "\(varName).setFixedLine(\(fixedLine.variableName));"

        let premiumRate = self.premiumRate.toJavascript()
        javascript += premiumRate.javascript
        javascript += "\(varName).setPremiumRate(\(premiumRate.variableName));"

        let sharedCost = self.sharedCost.toJavascript()
        javascript += sharedCost.javascript
        javascript += "\(varName).setSharedCost(\(sharedCost.variableName));"
        return (varName, javascript)
    }
}


let isTestData = true
var sharedInstance: PhoneNumberUtilJavascript = PhoneNumberUtilJavascript()

public class PhoneNumberUtilJavascript: PhoneNumberUtil {
    var phoneUtil:JSValue?
    static var phoneUtilClass:JSValue?
    let context:JSContext = JSContext()

    class func getInstance() -> PhoneNumberUtilJavascript {
        return sharedInstance
    }

    /*
        Just easy to read downloaded file then NSCache.
    */
    func cacheFilePath() -> String? {
        let path = NSTemporaryDirectory().stringByAppendingPathComponent("LibPhoneNumberSwift")
        var error:NSError?;
        if (!NSFileManager.defaultManager().fileExistsAtPath(path) && !NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil, error: &error)) {
            println("Cache File Directory making fail \(error)")
            return nil
        }
        return path.stringByAppendingPathComponent("libphonenumber.js")
    }

    func saveJavascript(string:String) {
        if let path = cacheFilePath() {
            var error:NSError?;
            string.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: &error)
            if let error = error {
                println("cache file save error: \(error)")
            }
        } else {
            println("cache file path search fail")
        }
    }

    func loadJavascript() -> String? {
        if let path = cacheFilePath() {
            var error:NSError?;
            if let result = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error) {
                println("cache file hit: \(path)")
                return result
            }
            if let error = error {
                println("cache file load error: \(error)")
            }
        } else {
            println("cache file path search fail")
        }
        return nil
    }

    func clearJavascript() {
        if let path = cacheFilePath() {
            var error:NSError?;
            if (!NSFileManager.defaultManager().removeItemAtPath(path, error:&error)) {
                println(" cache file clear success")
            }
            if let error = error {
                println("cache file load error: \(error)")
            }
        } else {
            println("cache file path search fail")
        }
    }

    /*
        FIXME: 2015.Feb.16, downloaded contents is too small and broken Javascript file.
        I should get compiled javascript library from the site manually.
    */
    func downloadLibrary() -> String? {
        let url:NSURL? = NSURL(string:"http://closure-compiler.appspot.com/compile")
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
        let session:NSURLSession = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"

        let libphonenumberJavascriptRepo = "https%3A%2F%2Fraw.githubusercontent.com%2Fgooglei18n%2Flibphonenumber%2Fmaster%2Fjavascript%2Fi18n%2Fphonenumbers%2F"
        let metadataFileName = isTestData ? "metadatafortesting.js" : "metadata.js"

        let body:String = "" +
            "output_format=json" +
            "&output_info=compiled_code" +
            "&output_info=errors" +
            "&compilation_level=SIMPLE_OPTIMIZATIONS" +
            "&use_closure_library=true" +
            "&code_url=" + libphonenumberJavascriptRepo + "phonemetadata.pb.js" +
            "&code_url=" + libphonenumberJavascriptRepo + "phonenumber.pb.js" +
            "&code_url=" + libphonenumberJavascriptRepo + metadataFileName +
            "&code_url=" + libphonenumberJavascriptRepo + "phonenumberutil.js" +
            "&code_url=" + libphonenumberJavascriptRepo + "asyoutypeformatter.js"

        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

        let semaphore = dispatch_semaphore_create(0);
        var result:String?
        let task = session.downloadTaskWithRequest(request, completionHandler: { (location:NSURL!, response:NSURLResponse!, error:NSError!) -> Void in
            if let error = error {
                println("Request Fail \(error)")
                dispatch_semaphore_signal(semaphore);
                return
            }
            let data = NSData(contentsOfURL: location)
            if data == nil {
                println("Request Fail without error")
                dispatch_semaphore_signal(semaphore);
                return
            }

            var error: NSError?
            if let data:NSData = data, json = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error) as? NSDictionary {
                if let error = json["errors"] as? NSArray {
                    println("Closure Compile Error: \(error)")
                    dispatch_semaphore_signal(semaphore);
                    return
                } else if let success = json["compiledCode"] as? String where error == nil {
                    result = success
                    dispatch_semaphore_signal(semaphore);
                    return
                }
            }
            if let error = error {
                println("Response Error: \(error)")
            }
            println("JSON Parsing Error with: \(NSString(data: data!, encoding: NSUTF8StringEncoding)!)")
            dispatch_semaphore_signal(semaphore);
        })

        task.resume()

        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (Int64)(60 * NSEC_PER_SEC)))
        return result
    }

    func loadLibrary(#javascript:String?) -> Bool {
        self.context.exceptionHandler = {(context, exception) -> Void in
            println("#### Javascript Exception: \(exception)")
        }
        if let result = self.context.evaluateScript(javascript) {
            println("Success Load libphonenumber library")
        } else {
            println("Fail evaluateScript libphonenumber library")
        }
        if let phoneUtilClass = self.context.globalObject.objectForKeyedSubscript("i18n").objectForKeyedSubscript("phonenumbers").objectForKeyedSubscript("PhoneNumberUtil") {
            if !phoneUtilClass.isUndefined() && !phoneUtilClass.isNull() {
                self.dynamicType.phoneUtilClass = phoneUtilClass
            }
        }
        self.context.evaluateScript("var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();");
        if let phoneUtil = self.context.globalObject?.objectForKeyedSubscript("phoneUtil") {
            if !phoneUtil.isUndefined() && !phoneUtil.isNull() {
                self.phoneUtil = phoneUtil
                println("Success Load LibPhoneNumber")
                return true
            } else {
                println("Fail Load LibPhoneNumber Object")
            }
        }
        return false
    }

    public init() {
        super.init(URL: NSURL(), countryCodeToRegionCodeMap: getCountryCodeToRegionCodeMap())
        var javascript:String? = loadJavascript()
        if javascript == nil {
            if let javascriptDownloaded = downloadLibrary() {
                saveJavascript(javascriptDownloaded)
                javascript = javascriptDownloaded
            }
        }
        if let javascript = javascript {
            if loadLibrary(javascript: javascript) == false {
                clearJavascript()
                println("############## PhoneNumberUtilJavascript init Fail ################")
            }
        }
    }

    // MARK: - Public instance APIs

    public override func getSupportedRegions() -> [String] {
        if let result = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments:nil)?.toArray() {
            return result as! [String]
        }
        return []
    }

    public override func getSupportedGlobalNetworkCallingCodes() -> [Int] {
        if let codes = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: nil)?.toArray() {
            return codes.reduce([], combine: { (var result:[Int], value) -> [Int] in
                if let code = value.integerValue {
                    result.append(code)
                }
                return result
            })
        }
        return []
    }
    public override func getRegionCodeForCountryCode(callingCode:Int) -> String {
        if let result = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [callingCode]) where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func getCountryCodeForRegion(countryCode:String) -> Int{
        if let result = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [countryCode]) where result.isNumber() {
            return result.toNumber().integerValue
        }
        return -1
    }
    public override func getMetadataForRegion(regionCode:String) -> PhoneMetadata? {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [regionCode]) where !(result.isNull() || result.isUndefined()) {
            return PhoneMetadata(javascriptValue:result)
        }
        return nil
    }
    public override func getMetadataForNonGeographicalRegion(countryCallingCode:Int) -> PhoneMetadata? {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [countryCallingCode]) where result.toDictionary() != nil  {
            return PhoneMetadata(javascriptValue:result)
        }
        return nil
    }
    public override func isNumberGeographical(phoneNumber:PhoneNumber) -> Bool {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func isLeadingZeroPossible(countryCallingCode:Int) -> Bool {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [countryCallingCode]) where result.isBoolean()  {
            return result.toBool()
        }
        return false
    }
    public override func getLengthOfGeographicalAreaCode(phoneNumber:PhoneNumber) -> Int {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isNumber() {
            return result.toNumber().integerValue
        }
        return -1
    }
    public override func getLengthOfNationalDestinationCode(phoneNumber:PhoneNumber) -> Int {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isNumber() {
            return result.toNumber().integerValue
        }
        return -1
    }
    public override func getNationalSignificantNumber(phoneNumber:PhoneNumber) -> String {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func getExampleNumber(regionCode:String) -> PhoneNumber? {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [regionCode]) where !(result.isNull() || result.isUndefined())  {
            return PhoneNumber(javascriptValue:result)
        }
        return nil
    }
    public override func getExampleNumberForType(regionCode:String, phoneNumberType:PhoneNumberType) -> PhoneNumber? {
        let functionName = __FUNCTION__.componentsSeparatedByString("(").first!
        let javascript = "phoneUtil.\(functionName)(\"\(regionCode)\", i18n.phonenumbers.PhoneNumberType.\(phoneNumberType.toString()));"
        if let result:JSValue = context.evaluateScript(javascript) where !(result.isNull() || result.isUndefined()) {
            return PhoneNumber(javascriptValue:result)
        }
        return nil
    }
    public override func getExampleNumberForNonGeoEntity(countryCallingCode:Int) -> PhoneNumber {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [countryCallingCode]) where !(result.isNull() || result.isUndefined()) {
            return PhoneNumber(javascriptValue:result)
        }
        return PhoneNumber()
    }
    public override func format(phoneNumber:PhoneNumber, numberFormat:PhoneNumberFormat) -> String {
        let args = "i18n.phonenumbers.PhoneNumberFormat.\(numberFormat.toString())"
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func formatOutOfCountryCallingNumber(phoneNumber:PhoneNumber, regionCallingFrom:String) -> String {
        let args = "\"\(regionCallingFrom)\""
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func formatOutOfCountryKeepingAlphaChars(phoneNumber:PhoneNumber, regionCallingFrom:String) -> String {
        let args = "\"\(regionCallingFrom)\""
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func formatNationalNumberWithCarrierCode(phoneNumber:PhoneNumber, carrierCode:String) -> String {
        let args = "\"\(carrierCode)\""
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func formatNationalNumberWithPreferredCarrierCode(phoneNumber:PhoneNumber, fallbackCarrierCode:String) -> String {
        let args = "\"\(fallbackCarrierCode)\""
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func formatNumberForMobileDialing(phoneNumber:PhoneNumber, regionCallingFrom:String, withFormatting:Bool) -> String {
        let args = "\"\(regionCallingFrom)\", \(withFormatting)"
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func formatByPattern(phoneNumber:PhoneNumber, numberFormat:PhoneNumberFormat, userDefinedFormats:[NumberFormat]) -> String {
        var args = [AnyObject]()
        args.append(phoneNumber)
        args.append("i18n.phonenumbers.PhoneNumberFormat.\(numberFormat.toString())")
        args += userDefinedFormats as [AnyObject]

        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: args).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func parseAndKeepRawInput(numberToParse:String, defaultRegion:String, error:NSErrorPointer) -> PhoneNumber {
        let previousExceptionHandler = self.context.exceptionHandler
        self.context.exceptionHandler = {(context, exception:JSValue!) -> Void in
            let type:ErrorType = ErrorType.parse(exception.toString())
            error.memory = NSError(domain:ErrorDomain, code:type.rawValue, userInfo:[NSLocalizedDescriptionKey:exception.toString()])
        }
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [numberToParse, defaultRegion]) where !(result.isNull() || result.isUndefined()) {
            self.context.exceptionHandler = previousExceptionHandler
            return PhoneNumber(javascriptValue:result)
        }
        self.context.exceptionHandler = previousExceptionHandler
        return PhoneNumber()
    }
    public override func formatInOriginalFormat(phoneNumber:PhoneNumber, regionCallingFrom:String) -> String {
        let args = "\"\(regionCallingFrom)\""
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func parse(numberToParse:String, defaultRegion:String, error:NSErrorPointer) -> PhoneNumber {
        let previousExceptionHandler = self.context.exceptionHandler
        self.context.exceptionHandler = {(context, exception:JSValue!) -> Void in
            let type:ErrorType = ErrorType.parse(exception.toString())
            error.memory = NSError(domain:ErrorDomain, code:type.rawValue, userInfo:[NSLocalizedDescriptionKey:exception.toString()])
        }
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [numberToParse, defaultRegion]) where !(result.isNull() || result.isUndefined()) {
            self.context.exceptionHandler = previousExceptionHandler
            return PhoneNumber(javascriptValue:result)
        }
        self.context.exceptionHandler = previousExceptionHandler
        return PhoneNumber()
    }
    public override func getNumberType(phoneNumber:PhoneNumber) -> PhoneNumberType {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isNumber() {
            if let type = PhoneNumberType(rawValue: result.toNumber().integerValue) {
                return type
            }
        }
        return PhoneNumberType.UNKNOWN
    }
    public override func isValidNumber(phoneNumber:PhoneNumber) -> Bool {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func isValidNumberForRegion(phoneNumber:PhoneNumber, regionCode:String) -> Bool {
        let args = "\"\(regionCode)\""
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber, args]).value where result.isNumber() {
        }
        return false
    }
    public override func getRegionCodeForNumber(phoneNumber:PhoneNumber) -> String {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func getRegionCodesForCountryCode(countryCallingCode:Int) -> [String] {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [countryCallingCode]) where !(result.isNumber() || result.isUndefined()) {
            return result.toArray().map({
                if let jsValue = $0 as? JSValue where jsValue.isString() {
                    return jsValue.toString()
                } else if let string = $0 as? String {
                    return string
                }
                return ""
            })
        }
        return [""]
    }
    public override func getNddPrefixForRegion(regionCode:String, stripNonDigits:Bool) -> String {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [regionCode, stripNonDigits]) where result.isString() {
            return result.toString()
        }
        return ""
    }
    public override func isNANPACountry(regionCode:String) -> Bool {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [regionCode]) where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func isPossibleNumber(phoneNumber:PhoneNumber) -> Bool {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func isPossibleNumber(number:String, regionDialingFrom:String) -> Bool {
        if let result:JSValue = self.phoneUtil?.invokeMethod("isPossibleNumberString", withArguments: [number, regionDialingFrom]) where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func isPossibleNumberWithReason(phoneNumber:PhoneNumber) -> ValidationResult {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isNumber() {
            if let validationResult = ValidationResult(rawValue:result.toNumber().integerValue) {
                return validationResult
            }
        }
        return ValidationResult.TOO_SHORT
    }
    public override func truncateTooLongNumber(phoneNumber:PhoneNumber) -> Bool {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func maybeStripNationalPrefixAndCarrierCode(number:String, metadata:PhoneMetadata, carrierCode:String) -> Bool {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [number, metadata, carrierCode]).value where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func maybeStripInternationalPrefixAndNormalize(number:String, possibleIddPrefix:String) -> CountryCodeSource {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [number, possibleIddPrefix]).value where result.isNumber() {
            if let type = CountryCodeSource(rawValue: result.toNumber().integerValue) {
                return type
            }
        }
        return CountryCodeSource.FROM_DEFAULT_COUNTRY
    }
    public override func maybeExtractCountryCode(number:String, defaultRegionMetadata:PhoneMetadata, keepRawInput:Bool, phoneNumber:PhoneNumber, error:NSErrorPointer) -> (countryCallingCode:Int, nationalNumber:String, phoneNumber:PhoneNumber) {
        let number = "\"\(number)\""
        let nationalNumberName = "nationalNumber_\(__LINE__)_StringBuffer"
        let previousExceptionHandler = self.context.exceptionHandler
        self.context.exceptionHandler = {(context, exception:JSValue!) -> Void in
            let type:ErrorType = ErrorType.parse(exception.toString())
            error.memory = NSError(domain:ErrorDomain, code:type.rawValue, userInfo:[NSLocalizedDescriptionKey:exception.toString()])
        }
        let resultTuple = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [number, defaultRegionMetadata, nationalNumberName, keepRawInput, phoneNumber])
        if let result = resultTuple.value where result.isNumber() {
            self.context.exceptionHandler = previousExceptionHandler
            var nationalNumber = ""
            if let numberResult = self.context.globalObject.objectForKeyedSubscript(nationalNumberName).invokeMethod("toString", withArguments: nil) where numberResult.isString() {
                nationalNumber = numberResult.toString()
            }
            var resultPhoneNumber = phoneNumber
            if let phoneNumberValue = self.context.globalObject.objectForKeyedSubscript(resultTuple.arguments[4]) where !(result.isNull() || result.isUndefined()) {
                resultPhoneNumber = PhoneNumber(javascriptValue:phoneNumberValue)
            }
            return (result.toNumber().integerValue, nationalNumber, phoneNumber.mergeFrom(resultPhoneNumber))
        }
        self.context.exceptionHandler = previousExceptionHandler
        return (-1, "", phoneNumber)
    }
    public override func isNumberMatch(firstString:String, secondString:String) -> MatchType {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: ["'\(firstString)'", "'\(secondString)'"]).value where result.isNumber() {
            if let type = MatchType(rawValue: result.toNumber().integerValue) {
                return type
            }
        }
        return MatchType.NOT_A_NUMBER
    }
    public override func isNumberMatch(firstNumber:PhoneNumber, secondString:String) -> MatchType {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [firstNumber, "'\(secondString)'"]).value where result.isNumber() {
            if let type = MatchType(rawValue: result.toNumber().integerValue) {
                return type
            }
        }
        return MatchType.NOT_A_NUMBER
    }
    public override func isNumberMatch(firstNumber:PhoneNumber, secondNumber:PhoneNumber) -> MatchType {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [firstNumber, secondNumber]).value where result.isNumber() {
            if let type = MatchType(rawValue: result.toNumber().integerValue) {
                return type
            }
        }
        return MatchType.NOT_A_NUMBER
    }
    public override func canBeInternationallyDialled(phoneNumber:PhoneNumber) -> Bool {
        if let result = self.context.invokeMethodWithNew(__FUNCTION__.componentsSeparatedByString("(").first!, args: [phoneNumber]).value where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
    public override func isAlphaNumber(number:String) -> Bool {
        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [number]) where result.isBoolean() {
            return result.toBool()
        }
        return false
    }
//    public override func isMobileNumberPortableRegion(regionCode:String) -> Bool {
//        if let result:JSValue = self.phoneUtil?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [regionCode]) where result.isBoolean() {
//            return result.toBool()
//        }
//        return false
//    }

    // MARK: - Class APIs

    public override class func getCountryMobileToken(countryCode:Int) -> String {
        if let result:JSValue = self.phoneUtilClass?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [countryCode]) where result.isString()  {
            return result.toString()
        }
        return ""
    }
    public override class func convertAlphaCharactersInNumber(input:String) -> String {
        if let result:JSValue = self.phoneUtilClass?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [input]) where result.isString()  {
            return result.toString()
        }
        return ""
    }
    public override class func normalize(phoneNumberString:String) -> String {
        if let result:JSValue = self.phoneUtilClass?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [phoneNumberString]) where result.isString()  {
            return result.toString()
        }
        return ""
    }
    public override class func normalizeDigitsOnly(inputNumber:String) -> String {
        if let result:JSValue = self.phoneUtilClass?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [inputNumber]) where result.isString()  {
            return result.toString()
        }
        return ""
    }
    public override class func normalizeDiallableCharsOnly(inputNumber:String) -> String {
        // TODO: should be implemented
        let functionName = __FUNCTION__.componentsSeparatedByString("(").first
        if let result:JSValue = self.phoneUtilClass?.invokeMethod(functionName, withArguments: [inputNumber]) where result.isString()  {
            return result.toString()
        }
        return ""
    }
    public override class func isViablePhoneNumber(number:String) -> Bool {
        if let result:JSValue = self.phoneUtilClass?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [number]) where result.isBoolean()  {
            return result.toBool()
        }
        return false
    }
    public override class func extractPossibleNumber(number:String) -> String {
        if let result:JSValue = self.phoneUtilClass?.invokeMethod(__FUNCTION__.componentsSeparatedByString("(").first, withArguments: [number]) where result.isString()  {
            return result.toString()
        }
        return ""
    }
    public override class func nsNumberMatch(firstNumberIn:PhoneNumber, secondNumberIn:PhoneNumber) -> MatchType {
        var varName = "phoneNumber_firstNumberIn"
        var javascript = " " +
            "var \(varName) = new i18n.phonenumbers.PhoneNumber();" +
            "\(varName).setCountryCode(\(firstNumberIn.countryCode));" +
        "\(varName).setNationalNumber(\(firstNumberIn.nationalNumber));"

        if firstNumberIn.isItalianLeadingZero {
            javascript += "\(varName).setItalianLeadingZero(\(firstNumberIn.isItalianLeadingZero));"
        }
        if let countryCodeSource = firstNumberIn.countryCodeSource {
            javascript += "\(varName).setCountryCodeSource(\(countryCodeSource.rawValue));"
        }
        if firstNumberIn.rawInput != "" {
            javascript += "\(varName).setRawInput(\"\(firstNumberIn.rawInput)\");"
        }
        if firstNumberIn.extensionFormat != "" {
            javascript += "\(varName).setExtension(\"\(firstNumberIn.extensionFormat)\");"
        }
        if firstNumberIn.numberOfLeadingZeros != 1 {
            javascript += "\(varName).setNumberOfLeadingZeros(\(firstNumberIn.numberOfLeadingZeros));"
        }
        if let preferredDomesticCarrierCode = firstNumberIn.preferredDomesticCarrierCode {
            javascript += "\(varName).setPreferredDomesticCarrierCode(\"\(preferredDomesticCarrierCode)\");"
        }

        varName = "phoneNumber_secondNumberIn"
        javascript = " " +
            "var \(varName) = new i18n.phonenumbers.PhoneNumber();" +
            "\(varName).setCountryCode(\(secondNumberIn.countryCode));" +
        "\(varName).setNationalNumber(\(secondNumberIn.nationalNumber));"

        if secondNumberIn.isItalianLeadingZero {
            javascript += "\(varName).setItalianLeadingZero(\(secondNumberIn.isItalianLeadingZero));"
        }
        if let countryCodeSource = secondNumberIn.countryCodeSource {
            javascript += "\(varName).setCountryCodeSource(\(countryCodeSource.rawValue));"
        }
        if secondNumberIn.rawInput != "" {
            javascript += "\(varName).setRawInput(\"\(secondNumberIn.rawInput)\");"
        }
        if secondNumberIn.extensionFormat != "" {
            javascript += "\(varName).setExtension(\"\(secondNumberIn.extensionFormat)\");"
        }
        if secondNumberIn.numberOfLeadingZeros != 1 {
            javascript += "\(varName).setNumberOfLeadingZeros(\(secondNumberIn.numberOfLeadingZeros));"
        }
        if let preferredDomesticCarrierCode = secondNumberIn.preferredDomesticCarrierCode {
            javascript += "\(varName).setPreferredDomesticCarrierCode(\"\(preferredDomesticCarrierCode)\");"
        }

        javascript += "i18n.phonenumbers.PhoneNumberUtil.nsNumberMatch(phoneNumber_firstNumberIn, phoneNumber_secondNumberIn);"
        if let result:JSValue = self.phoneUtilClass?.context.evaluateScript(javascript) where result.isNumber() {
            if let type = MatchType(rawValue:result.toNumber().integerValue) {
                return type
            }
        }
        return MatchType.NO_MATCH
    }
}
