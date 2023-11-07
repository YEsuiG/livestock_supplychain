// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract MyContract is Ownable, AccessControl {

    // Define the roles with the AccessControl framework
    bytes32 public constant HERDER_ROLE = keccak256("HERDER");
    bytes32 public constant SLAUGHTERHOUSE_ROLE = keccak256("SLAUGHTERHOUSE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER");
    bytes32 public constant MARKET_ROLE = keccak256("MARKET");
    bytes32 public constant INDIVIDUAL_ROLE = keccak256("INDIVIDUAL");

    // Define enums with consistent naming
    enum LivestockType { SHEEP, GOAT, BEEF, CAMEL, HORSE }
    enum OrderStatus { PENDING, CONFIRMED, IN_TRANSIT, COMPLETED, CANCELED }

    // Counter for generating unique IDs
    uint256 private herderIdCounter = 1;
    
    // Define structs for each stakeholder
    struct Herder {
        uint256 id;
        string location;
        uint256 grade;
        mapping(LivestockType => uint256) livestockInventory;
        mapping(LivestockType => uint256) pricePerKg;
        bool registered;
    }
    
    struct Slaughterhouse {
        uint256 id;
        uint256 location;
        uint256[] pricePerKg;
        bool registered;
    }
    
    struct Transporter {
        uint256 id;
        string truckInfo;
        uint256 pricePerKm;
        bool registered;
    }
    
    struct Market {
        uint256 id;
        uint256 location;
        uint256[] pricePerKg;
        bool registered;
    }
    
    struct Individual {
        uint256 id;
        uint256 location;
        bool registered;
    }

    // Define struct for orders
    struct Order {
        uint256 id;
        address buyer;
        address seller;
        LivestockType livestockType;
        uint256 quantity;
        uint256 price;
        OrderStatus status;
    }
    // Structure to hold Aimag data
    struct Aimag {
        uint256 pastureCarryingCapacity;
        uint256 totalLivestockNumber;
        uint256 totalHerderNumber;
    }
    
    // Define events with parameters
    event RegisteredHerder(uint256 indexed herderId, uint256 grade);
    event OrderPlaced(uint256 indexed orderId, address indexed buyer, uint256 amount);
    event OrderConfirmed(uint256 indexed orderId);
    event TransportationRequested(uint256 indexed orderId, address indexed transporter);
    event DeliveryConfirmed(uint256 indexed orderId);
    event LivestockPickedUp(uint256 indexed orderId, uint256 quantityPickedUp);
    event PaymentMade(uint256 indexed orderId, uint256 amount);
    event LivestockDelivered(uint256 indexed orderId, uint256[] earTagNumbers);
    event OrderCanceled(uint256 indexed orderId);
    
    // Define state variables
    mapping(uint256 => Herder) public herders;
    mapping(address => Slaughterhouse) public slaughterhouses;
    mapping(address => Transporter) public transporters;
    mapping(address => Market) public markets;
    mapping(address => Individual) public individuals;
    mapping(uint256 => Order) public orders;
    mapping(uint256 => uint256) public escrowedFunds;
    // Mapping to hold the data for each Aimag
    mapping(string => Aimag) public aimags;
    // Mapping to link an Ethereum address with its numerical herder ID
    mapping(address => uint256) public herderAddressToId;
    
    uint256 public nextOrderId = 1;

    // Modifiers for access control
    modifier onlyHerder() {
        require(hasRole(HERDER_ROLE, msg.sender), "Caller is not a herder");
        _;
    }

    modifier onlySlaughterhouse() {
        require(hasRole(SLAUGHTERHOUSE_ROLE, msg.sender), "Caller is not a slaughterhouse");
        _;
    }
    
    modifier onlyTransporter() {
        require(hasRole(TRANSPORTER_ROLE, msg.sender), "Caller is not a transporter");
        _;
    }

    modifier onlyMarket() {
        require(hasRole(MARKET_ROLE, msg.sender), "Caller is not a market");
        _;
    }
    
    modifier onlyIndividual() {
        require(hasRole(INDIVIDUAL_ROLE, msg.sender), "Caller is not an individual");
        _;
    }

    // Constructor to initialize the Aimag data
    constructor() Ownable(msg.sender) {
        // Set the deployer as the admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initialize Aimag data
        initializeAimagData();
    }

    // Function to initialize Aimag data
    function initializeAimagData() internal {
        aimags["Zavhan"] = Aimag(3607000, 3721060, 9860);
        aimags["Gobi-Altai"] = Aimag(2780000, 3167470, 8140);
        aimags["Bayan-Ulgii"] = Aimag(854600, 2255810, 10160);
        aimags["Khovd"] = Aimag(758000, 3472850, 8530);
        aimags["Uvs"] = Aimag(1128000, 3513850, 9960);
        aimags["Orkhon"] = Aimag(170000, 169940, 980);
        aimags["Uvurkhangai"] = Aimag(4120000, 4589390, 17830);
        aimags["Bulgan"] = Aimag(3950100, 3892840, 9060);
        aimags["Bayankhongor"] = Aimag(725000, 3719590, 13110);
        aimags["Arkhangai"] = Aimag(1910100, 5886090, 16170);
        aimags["Khuvsgul"] = Aimag(6478500, 6254100, 19540);
        aimags["Tuv"] = Aimag(5103000, 5107700, 13420);
        aimags["Gobi-Sumber"] = Aimag(521150, 464290, 800);
        aimags["Selenge"] = Aimag(2860300, 1912340, 5540);
        aimags["Dornogobi"] = Aimag(1620000, 2909700, 4650);
        aimags["Darkhan-Uul"] = Aimag(575600, 313210, 1230);
        aimags["Umnugobi"] = Aimag(517000, 2637330, 6580);
        aimags["Dundgobi"] = Aimag(2150600, 3626370, 7680);
        aimags["Dornod"] = Aimag(4926000, 3342320, 6160);
        aimags["Sukhbaatar"] = Aimag(5120300, 4644800, 8950);
        aimags["Khentii"] = Aimag(5100020, 5076550, 9100);
        aimags["Ulaanbaatar"] = Aimag(417030, 442840, 3310);
    }

    
    // Functions for each stakeholder to register themselves
    // Function to register a herder
    function registerHerder(
    string memory locationKey,
    uint256[] memory livestockByType
    //uint256[] memory pricePerKg
    ) public onlyHerder {
    // Check if the sender has already registered as a herder
    require(herderAddressToId[msg.sender] == 0, "Herder already registered.");

    // Use the counter to assign a new unique ID
    uint256 herderId = herderIdCounter++;

    // Retrieve the Aimag data
    Aimag storage aimag = aimags[locationKey];
    require(aimag.pastureCarryingCapacity > 0, "Invalid location");

    // Calculate grade points and grade
    uint256 gradePoints = calculateGradePoints(aimag, livestockByType);
    uint256 grade = getGrade(gradePoints);

    // Create and store the new Herder struct
    Herder storage newHerder = herders[herderId];
    newHerder.id = herderId;
    newHerder.location = locationKey;
    // Assign livestockInventory and pricePerKg based on input arrays
    // You will need to implement this logic based on how you want to store these values
    newHerder.grade = grade;
    newHerder.registered = true;

    // Map the sender's address to the new herder ID
    herderAddressToId[msg.sender] = herderId;

    // Emit the event with the new herder's information including the grade
    emit RegisteredHerder(herderId, grade);
    }

    // Helper function to calculate grade points based on Aimag data
    function calculateGradePoints(Aimag storage aimag, uint256[] memory livestockByType) internal view returns (uint256) {
        uint256 pcr = aimag.totalLivestockNumber / aimag.pastureCarryingCapacity;
        uint256 livestockPerHerder = aimag.pastureCarryingCapacity / (aimag.totalHerderNumber); 
        uint256 totalLivestock = 0;
        for (uint256 i = 0; i < livestockByType.length; i++) {
            totalLivestock = totalLivestock + livestockByType[i];
        }
        return pcr + (totalLivestock / livestockPerHerder);
    }
    // Implement a the getGrade function
    function getGrade(uint256 gradePoints) internal pure returns (uint256) {
        if (gradePoints <= 2) return 1;
        if (gradePoints <= 4) return 2;
        if (gradePoints <= 6) return 3;
        if (gradePoints <= 8) return 4;
        return gradePoints <= 10 ? 5 : 6;
    }
    function registerSlaughterhouse(uint location, uint[] memory pricePerKg) public onlySlaughterhouse {
        Slaughterhouse storage sh = slaughterhouses[msg.sender];
        require(!sh.registered, "Slaughterhouse already registered.");

        sh.registered = true;
        sh.location = location;
        sh.pricePerKg = pricePerKg;
    }

    function registerTransporter(string memory truckInfo, uint pricePerKm) public onlyTransporter {
        Transporter storage tr = transporters[msg.sender];
        require(!tr.registered, "Transporter already registered.");

        tr.registered = true;
        tr.truckInfo = truckInfo;
        tr.pricePerKm = pricePerKm;
    }
    
    function registerMarket(uint location, uint[] memory pricePerKg) public onlyMarket {
        Market storage m = markets[msg.sender];
        require(!m.registered, "Market already registered.");

        m.registered = true;
        m.location = location;
        m.pricePerKg = pricePerKg;
    }
    
    function registerIndividual(uint location) public onlyIndividual {
        Individual storage ind = individuals[msg.sender];
        require(!ind.registered, "Individual already registered.");

        ind.registered = true;
        ind.location = location;
    }

    // Function to place an order
    function placeOrder(address seller, LivestockType livestockType, uint256 quantity) public payable {
         uint256 herderId = herderAddressToId[seller];
    
        require(herderId != 0, "Seller is not a registered herder.");
        require(seller != msg.sender, "Cannot place an order with yourself.");
        Herder storage herder = herders[herderId];
        require(herder.registered, "Seller is not a registered herder.");
        uint256 stockAvailable = herder.livestockInventory[livestockType];
        require(stockAvailable >= quantity, "Not enough livestock available.");
        uint256 price = herder.pricePerKg[livestockType] * quantity;
        require(msg.value == price, "Incorrect Ether amount sent.");

        escrowedFunds[nextOrderId] = msg.value;

        Order storage newOrder = orders[nextOrderId];
        newOrder.id = nextOrderId;
        newOrder.buyer = msg.sender;
        newOrder.seller = seller;
        newOrder.livestockType = livestockType;
        newOrder.quantity = quantity;
        newOrder.price = price;
        newOrder.status = OrderStatus.PENDING;

        nextOrderId++;

        emit OrderPlaced(newOrder.id, msg.sender, price);
    }

    // Function to confirm an order
    function confirmOrder(uint256 orderId, bool confirm) public onlyHerder {
        require(orders[orderId].seller == msg.sender, "Only the seller can confirm the order");
        require(orders[orderId].status == OrderStatus.PENDING, "Order is not pending.");
        
        if (confirm) {
            orders[orderId].status = OrderStatus.CONFIRMED;
            emit OrderConfirmed(orderId);
        } else {
            orders[orderId].status = OrderStatus.CANCELED;
            uint256 refund = escrowedFunds[orderId];
            delete escrowedFunds[orderId];
            payable(orders[orderId].buyer).transfer(refund);
            emit OrderCanceled(orderId);
        }
    }

    // Function to request transportation
    function requestTransportation(uint256 orderId, address transporter) public {
        require(orders[orderId].buyer == msg.sender, "Only the buyer can request transportation");
        require(orders[orderId].status == OrderStatus.CONFIRMED, "Order not confirmed yet");
        
        orders[orderId].status = OrderStatus.IN_TRANSIT;
        emit TransportationRequested(orderId, transporter);
    }

    // Function to confirm delivery request
    function confirmDeliveryRequest(uint256 orderId) public onlyTransporter {
        require(orders[orderId].status == OrderStatus.IN_TRANSIT, "Transport request not in transit state");
        emit DeliveryConfirmed(orderId);
    }

    // Function to confirm pick up
    function confirmPickUp(uint256 orderId, uint256 quantityPickedUp) public onlyTransporter {
        require(orders[orderId].status == OrderStatus.IN_TRANSIT, "Order must be in transit");
        emit LivestockPickedUp(orderId, quantityPickedUp);
    }

    // Function to confirm delivery
    function confirmDelivery(uint256 orderId, uint256[] calldata earTagNumbers) public {
        require(orders[orderId].status == OrderStatus.IN_TRANSIT, "Order must be in transit");
        require(orders[orderId].buyer == msg.sender, "Only the buyer can confirm delivery");
        
        orders[orderId].status = OrderStatus.COMPLETED;
        uint256 payment = escrowedFunds[orderId];
        delete escrowedFunds[orderId];
        payable(orders[orderId].seller).transfer(payment);
        
        emit LivestockDelivered(orderId, earTagNumbers);
    }

    // Function to cancel the order
    function cancelOrder(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(msg.sender == order.seller || msg.sender == order.buyer, "Only buyer or seller can cancel");
        require(order.status == OrderStatus.PENDING, "Order is not pending");
        
        order.status = OrderStatus.CANCELED;
        uint256 refund = escrowedFunds[orderId];
        delete escrowedFunds[orderId];
        payable(order.buyer).transfer(refund);

        emit OrderCanceled(orderId);
    }

}
