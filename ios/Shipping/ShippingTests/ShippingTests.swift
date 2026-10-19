//
//  ShippingTests.swift
//  ShippingTests
//
//  Created by roei baruch on 13/10/2026.
//

import Foundation
import Testing
@testable import Shipping

// MARK: - Test doubles (one configurable spy per dependency)

@MainActor
final class SpyShipmentService: ShipmentServiceProtocol {
    var shipmentsResult: Result<[Shipment], Error> = .success([])
    var createResult: Result<Shipment, Error> = .success(Shipment(id: "abc123-0000", status: .preparingOptions))
    var detailsResult: Result<ShipmentDetails, Error> = .success(ShipmentDetails(id: "s1", status: .optionsReady, options: []))
    var approveResult: Result<Shipment, Error> = .success(Shipment(id: "s1", status: .approved))

    private(set) var createCalls: [ShipmentRequest] = []
    private(set) var approveCalls: [(id: String, optionId: String)] = []

    func fetchShipments() async throws -> [Shipment] { try shipmentsResult.get() }

    func create(_ request: ShipmentRequest) async throws -> Shipment {
        createCalls.append(request)
        return try createResult.get()
    }

    func fetchShipment(id: String) async throws -> ShipmentDetails { try detailsResult.get() }

    func approve(id: String, optionId: String) async throws -> Shipment {
        approveCalls.append((id, optionId))
        return try approveResult.get()
    }

    func registerDevice(token: String) async throws {}
}

@MainActor
final class StubAuthService: AuthServiceProtocol {
    var result: Result<String, Error> = .success("token-from-server")
    func login(username: String, password: String) async throws -> String {
        try result.get()
    }
}

private let calendar = Calendar.current
private let today = calendar.startOfDay(for: Date())

private func day(_ offset: Int) -> Date {
    calendar.date(byAdding: .day, value: offset, to: today)!
}

private func validForm() -> ShipmentForm {
    ShipmentForm(quantity: "1200", weightKg: "9800",
                 lengthCm: "120", widthCm: "80", heightCm: "150",
                 packageType: .bottles, deliveryDate: day(30), shippingMode: .sea,
                 pickupAddress: "Corona Brewery, Mexico City", deliveryAddress: "Bar, Berlin",
                 priority: .lowestPrice, temperatureControl: true,
                 customsBy: .buyer, insuranceBy: .seller, localTruckingBy: .buyer, incoterms: .fob)
}

private func option(_ id: String, _ mode: ShippingMode, price: Double, arrival: Int) -> ShippingOption {
    ShippingOption(id: id, mode: mode, price: price, estimatedArrival: day(arrival), containerType: mode == .sea ? .fortyFt : .uld)
}

// MARK: - Pure calculators

@MainActor
struct OptionRankCalculatorTests {
    let calculator = OptionRankCalculator()

    @Test func marksCheapestAndFastest() {
        let ranks = calculator.calcRanks(for: [option("sea", .sea, price: 4800, arrival: 36),
                                               option("air", .air, price: 14200, arrival: 15)])
        #expect(ranks["sea"] == OptionRank(isCheapest: true, isFastest: false))
        #expect(ranks["air"] == OptionRank(isCheapest: false, isFastest: true))
    }

    @Test func singleOptionGetsNoLabels() {
        #expect(calculator.calcRanks(for: [option("sea", .sea, price: 4800, arrival: 36)]).isEmpty)
    }
}

@MainActor
struct ShipmentFormValidatorTests {
    let validator = ShipmentFormValidator()

    @Test func validFormBuildsRequest() throws {
        guard case .valid(let request) = validator.validate(validForm(), today: today) else {
            Issue.record("expected valid")
            return
        }
        #expect(request.quantity == 1200)
        #expect(request.weightKg == 9800)
        #expect(request.incoterms == .fob)
    }

    @Test func zeroQuantityAndBlankWeightAreRejected() {
        var form = validForm()
        form.quantity = "0"
        form.weightKg = ""
        #expect(validator.validate(form, today: today) == .invalid([
            FieldError(field: "quantity", message: "Must be greater than 0"),
            FieldError(field: "weightKg", message: "Required")
        ]))
    }

    @Test func deliveryDateTodayIsNotFuture() {
        var form = validForm()
        form.deliveryDate = today
        #expect(validator.validate(form, today: today) == .invalid([
            FieldError(field: "deliveryDate", message: "Must be a future date")
        ]))
    }

    @Test func unpickedDropdownIsRequired() {
        var form = validForm()
        form.incoterms = nil
        #expect(validator.validate(form, today: today) == .invalid([
            FieldError(field: "incoterms", message: "Required")
        ]))
    }
}

@MainActor
struct ShipmentFormatterTests {
    let formatter = ShipmentFormatter()

    @Test func shortIdIsFirstSixHexUppercased() {
        #expect(formatter.shipmentTitle("3f9a2c10-7b1e-4c55") == "Shipment #3F9A2C")
    }

    @Test func optionTitleCombinesModeAndRank() {
        #expect(formatter.optionTitle(mode: .sea, rank: OptionRank(isCheapest: true)) == "Sea · Lowest price")
        #expect(formatter.optionTitle(mode: .air, rank: nil) == "Air")
    }

    @Test func priceHasNoCents() {
        #expect(formatter.price(4800) == "$4,800")
    }
}

// MARK: - Endpoints

@MainActor
struct EndPointTests {
    @Test func approveBuildsPostWithOptionIdBody() throws {
        let endPoint = EndPoint.approve(id: "abc", optionId: "opt1")
        let request = try #require(endPoint.request)

        #expect(request.url?.path == "/customer/shipments/abc/approve")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json == ["optionId": "opt1"])
        #expect(endPoint.requiresAuth)
    }

    @Test func loginSendsCredentialsAndSkipsToken() throws {
        let endPoint = EndPoint.login(username: "bar", password: "secret")
        let body = try #require(endPoint.request?.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

        #expect(json == ["username": "bar", "password": "secret"])
        #expect(endPoint.requiresAuth == false)
    }

    @Test func getHasNoBody() throws {
        let request = try #require(EndPoint.shipments.request)
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
    }
}

// MARK: - View models

@MainActor
struct NewShipmentViewModelTests {
    @Test func invalidFormNeverCallsServer() async {
        let spy = SpyShipmentService()
        let vm = NewShipmentViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"))
        await vm.submit()   // empty form

        #expect(spy.createCalls.isEmpty)
        guard case .failure(let errors) = vm.phase else {
            Issue.record("expected failure")
            return
        }
        #expect(errors.contains { $0.id == "quantity" })
        #expect(vm.isInvalid("quantity"))
    }

    @Test func validFormSubmitsOnceAndShowsSuccess() async {
        let spy = SpyShipmentService()
        let vm = NewShipmentViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"))
        vm.form = validForm()
        await vm.submit()

        #expect(spy.createCalls.count == 1)
        #expect(vm.phase == .success(SubmitSuccessState(requestTitle: "Request #ABC123",
                                                        statusText: "Preparing options")))
    }

    @Test func server422ShowsServerMessagesAndFixReturnsToForm() async {
        let spy = SpyShipmentService()
        spy.createResult = .failure(NetworkError.validation([FieldError(field: "deliveryDate", message: "Must be a future date")]))
        let vm = NewShipmentViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"))
        vm.form = validForm()
        await vm.submit()

        #expect(vm.phase == .failure([FieldErrorState(id: "deliveryDate", label: "Delivery date", message: "Must be a future date")]))
        vm.fix()
        #expect(vm.phase == .editing)
        #expect(vm.isInvalid("deliveryDate"))
    }

    @Test func unauthorizedDeletesToken() async {
        let spy = SpyShipmentService()
        spy.createResult = .failure(NetworkError.unauthorized)
        let keychain = InMemoryKeychainService(token: "token")
        let vm = NewShipmentViewModel(service: spy, keychain: keychain)
        vm.form = validForm()
        await vm.submit()

        #expect(keychain.token == nil)
    }
}

@MainActor
struct OptionsViewModelTests {
    @Test func loadMapsCardsWithRankTitles() async {
        let spy = SpyShipmentService()
        spy.detailsResult = .success(ShipmentDetails(id: "s1", status: .optionsReady, options: [
            option("sea", .sea, price: 4800, arrival: 36),
            option("air", .air, price: 14200, arrival: 15)
        ]))
        let vm = OptionsViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"), shipmentId: "s1")
        await vm.load()

        #expect(vm.cards.map(\.title) == ["Sea · Lowest price", "Air · Fastest"])
        #expect(vm.canApprove == false)   // nothing selected yet
    }

    @Test func approveWithoutSelectionDoesNothing() async {
        let spy = SpyShipmentService()
        let vm = OptionsViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"), shipmentId: "s1")
        await vm.approve()
        #expect(spy.approveCalls.isEmpty)
    }

    @Test func approveSendsSelectedOption() async {
        let spy = SpyShipmentService()
        let vm = OptionsViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"), shipmentId: "s1")
        vm.select("sea")
        await vm.approve()

        #expect(spy.approveCalls.count == 1)
        #expect(spy.approveCalls.first?.optionId == "sea")
        #expect(vm.isApproved)
    }

    @Test func conflictShowsMessageAndStaysOpen() async {
        let spy = SpyShipmentService()
        spy.approveResult = .failure(NetworkError.conflict)
        let vm = OptionsViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"), shipmentId: "s1")
        vm.select("sea")
        await vm.approve()

        #expect(vm.isApproved == false)
        #expect(vm.errorMessage == "This shipment was already approved.")
    }
}

@MainActor
struct HomeViewModelTests {
    @Test func onlyOptionsReadyRowsAreTappable() async {
        let spy = SpyShipmentService()
        spy.shipmentsResult = .success([Shipment(id: "a", status: .optionsReady),
                                        Shipment(id: "b", status: .preparingOptions)])
        let vm = HomeViewModel(service: spy, keychain: InMemoryKeychainService(token: "token"))
        await vm.load()

        #expect(vm.rows.map(\.isTappable) == [true, false])
        vm.select(vm.rows[1])
        #expect(vm.options == nil)
        vm.select(vm.rows[0])
        #expect(vm.options != nil)
    }

    @Test func unauthorizedDeletesToken() async {
        let spy = SpyShipmentService()
        spy.shipmentsResult = .failure(NetworkError.unauthorized)
        let keychain = InMemoryKeychainService(token: "token")
        await HomeViewModel(service: spy, keychain: keychain).load()

        #expect(keychain.token == nil)
    }

    @Test func logoutDeletesTokenAndClearsFeed() async {
        let spy = SpyShipmentService()
        spy.shipmentsResult = .success([Shipment(id: "a", status: .optionsReady)])
        let keychain = InMemoryKeychainService(token: "token")
        let vm = HomeViewModel(service: spy, keychain: keychain)
        await vm.load()
        vm.logout()

        #expect(keychain.token == nil)
        #expect(vm.rows.isEmpty)
    }
}

@MainActor
struct LoginViewModelTests {
    @Test func wrongPasswordShowsMessageAndSavesNothing() async {
        let auth = StubAuthService()
        auth.result = .failure(NetworkError.unauthorized)
        let keychain = InMemoryKeychainService()
        let vm = LoginViewModel(auth: auth, keychain: keychain)
        vm.username = "bar"
        vm.password = "nope"
        await vm.login()

        #expect(keychain.token == nil)
        #expect(vm.errorMessage == "Wrong username or password")
    }

    @Test func successSavesTokenFromServer() async {
        let keychain = InMemoryKeychainService()
        let vm = LoginViewModel(auth: StubAuthService(), keychain: keychain)
        vm.username = "bar"
        vm.password = "secret"
        await vm.login()

        #expect(keychain.token == "token-from-server")
    }
}
