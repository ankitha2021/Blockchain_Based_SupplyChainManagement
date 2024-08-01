//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract DataInputModule {
   
    event DataCaptured(string role, string data, uint price);

    modifier onlyFarmer(string memory role) {
        require(keccak256(bytes(role)) == keccak256(bytes("Farmer")),"Only farmer can enter raw material");
        _;
    }

    mapping(address => string) public stakeholders;
    string role;
    function assignRole(address _stakeholder, string memory _role) public{
        stakeholders[_stakeholder] = _role;
        role = _role;
    }

    
    function rawMaterialData(string memory _data, uint price) public onlyFarmer(role) {
        emit DataCaptured(role, _data,price);
    }

}

contract Manufacturing {
    UserInterfaceModule supplyChain;
    ComplianceAndCertificationModule complianceModule =  new ComplianceAndCertificationModule(); 
    constructor(UserInterfaceModule _supplyChain) {
        supplyChain = _supplyChain;
    }
    event DataStored(string role, string data);
    string role;
    
    modifier onlyManufacturer(string memory role) {
        require(keccak256(bytes(role)) == keccak256(bytes("Manufacturer")),"Only manufacturer");
        bool isCompliant = complianceModule.checkCompliance("Quality Standards");
        require(!isCompliant, "Product does not meet quality standards");
        _;
    }

    
    mapping(address => string) public stakeholders;

    
    function assignRole(address _stakeholder, string memory _role) public {
        stakeholders[_stakeholder] = _role;
        role=_role;
    }
    

    function buyRawMaterial(uint256 _productId,uint amnt) public payable onlyManufacturer(role) {
        
        uint256 productIdCounter = supplyChain.getProductIdCounter();
        (string memory name, uint price, address farmer, bool isPurchased) = supplyChain.getRawMaterialDetails(_productId);
        require(_productId > 0 && _productId <= productIdCounter, "Invalid product ID");
        //console.log(name,price,farmer,isPurchased);
        
        require(!isPurchased, "Product already purchased");

        //console.log("price ",price);
        //console.log("value is ",amnt);
        require(uint(amnt) > price, "Insufficient payment");
        

        supplyChain.updateRawMaterialPurchased(_productId, true);
    }
    event DataCaptured(string role, string data, uint price);
    function ManufacturedData(string memory _data, uint price) public onlyManufacturer(role) {
        emit DataCaptured(role, _data,price);
    }

    
}

contract Distribution{
    UserInterfaceModule supplyChain;
    constructor(UserInterfaceModule _supplyChain) {
        supplyChain = _supplyChain;
    }
    event DataStored(string role, string data);
    string role;
    
    modifier onlyDistributor(string memory role, uint256 _productId) {
        (string memory name, uint price, address farmer, bool isPurchased) = supplyChain.getRawMaterialDetails(_productId);
        require(isPurchased,"Raw materials not yet purchased");
        require(keccak256(bytes(role)) == keccak256(bytes("Distributor")),"Only distributor");
        _;
    }

    mapping(address => string) public stakeholders;

    function assignRole(address _stakeholder, string memory _role) public {
        stakeholders[_stakeholder] = _role;
        role=_role;
    }


    function buyManufactured(uint256 _productId,uint amnt) public payable onlyDistributor(role, _productId) {
        
        uint256 productIdCounter = supplyChain.getProductIdCounter();
        (string memory name, uint price, address manufacturer, bool isPurchased) = supplyChain.getManufacturedDetails(_productId);
        require(_productId > 0 && _productId <= productIdCounter, "Invalid product ID");
        //console.log(name,price,manufacturer,isPurchased);
    
        require(!isPurchased, "Product already purchased");

        //console.log("price ",price);
        //console.log("value is ",amnt);
        require(uint(amnt) > price, "Insufficient payment");

        supplyChain.updateMaufacturedPurchased(_productId, true);
        
    }
    
}

contract ProductTraceabilityModule {

    UserInterfaceModule supplyChain;
    constructor(UserInterfaceModule _supplyChain) {
        supplyChain = _supplyChain;
    }
    function traceProductJourney(uint256 _productId) view public 
    returns(uint ,address , bool ,uint , address , bool )
    {
        (, uint FarmerPrice, address farmer, bool FarmerSold) = supplyChain.getRawMaterialDetails(_productId);
        (, uint ManufacturerPrice, address manufacturer, bool ManufacturerSold) = supplyChain.getManufacturedDetails(_productId);
        return (FarmerPrice,farmer,FarmerSold,ManufacturerPrice,manufacturer, ManufacturerSold);
    }

    }


contract ComplianceAndCertificationModule {
   
    event RegulatoryDocumentStored(address indexed sender, string document);
    string role;
    
    modifier onlyGovernmentAgency(string memory role) {
        require(keccak256(bytes(role)) == keccak256(bytes("GovernmentAgency")),"Only Government agency");
        _;
    }
    mapping(address => string) public stakeholders;

    function assignRole(address _stakeholder, string memory _role) public {
        stakeholders[_stakeholder] = _role;
        role=_role;
    }

     struct ComplianceRule {
        string description;
        bool isCompliant;
    }

    mapping(string => ComplianceRule) public complianceRules;


     function setComplianceRule(string memory _ruleDescription) public onlyGovernmentAgency(role) {
        complianceRules[_ruleDescription] = ComplianceRule(_ruleDescription, true);
    }

    function checkCompliance(string memory _ruleDescription) public view returns (bool) {
        return complianceRules[_ruleDescription].isCompliant;
    }

}


contract UserInterfaceModule {
    DataInputModule dataInputModule;
    Manufacturing manufacturing;
    Distribution distributor;
    ProductTraceabilityModule productTraceabilityModule;
    ComplianceAndCertificationModule complianceAndCertificationModule;

    struct ProductFarmer {
        string name;
        uint price;
        address farmer;
        bool isPurchased;
    }
    ProductFarmer sellProduct1;

     mapping(uint256 => ProductFarmer) public products;
     uint256 productIdCounter;


    struct ProductManufacturer {
        string name;
        uint price;
        address manufacturer;
        bool isPurchased;
    }
    ProductManufacturer sellProduct2;
    mapping(uint256 => ProductManufacturer) public products2;
   
    constructor() {
        dataInputModule = new DataInputModule();
        manufacturing = new Manufacturing(this);
        distributor = new Distribution(this);
        productTraceabilityModule = new ProductTraceabilityModule(this);
        complianceAndCertificationModule = new ComplianceAndCertificationModule();
        productIdCounter = 0;
    }

    function assignRole(address _stakeholder, string memory _role, string memory _module) public returns(string memory){
        if (keccak256(abi.encodePacked(_module)) == keccak256(abi.encodePacked("DataInputModule"))) {
            dataInputModule.assignRole(_stakeholder, _role);
            sellProduct1.farmer = _stakeholder;
            return "farmer assigned";
        } else if (keccak256(abi.encodePacked(_module)) == keccak256(abi.encodePacked("Manufacturing"))) {
            sellProduct2.manufacturer = _stakeholder;
            manufacturing.assignRole(_stakeholder, _role);
        } else if (keccak256(abi.encodePacked(_module)) == keccak256(abi.encodePacked("ComplianceAndCertificationModule"))) {
            complianceAndCertificationModule.assignRole(_stakeholder, _role);
        }
        else if (keccak256(abi.encodePacked(_module)) == keccak256(abi.encodePacked("Distribution"))) {
            distributor.assignRole(_stakeholder, _role);
        }
        return "";
    }

    function rawMaterialData(string memory _data,uint price) public {
        dataInputModule.rawMaterialData(_data,price);
        productIdCounter++;
        products[productIdCounter] = ProductFarmer(_data, price, sellProduct1.farmer, false);
       
    }

    function ManufacturedData(string memory _data,uint price) public {
        manufacturing.ManufacturedData(_data,price);
        productIdCounter++;
        products2[productIdCounter] = ProductManufacturer(_data, price, sellProduct2.manufacturer, false);
       
    }

    
    function getProductIdCounter() public view returns (uint256) {
    return productIdCounter;
    }

    function getRawMaterialDetails(uint256 _productId) public view returns (string memory, uint, address, bool) {
    require(_productId > 0 && _productId <= productIdCounter, "Invalid product ID");
    ProductFarmer memory product = products[_productId];
    return (product.name, product.price, product.farmer, product.isPurchased);
    }

    function getManufacturedDetails(uint256 _productId) public view returns (string memory, uint, address, bool) {
    require(_productId > 0 && _productId <= productIdCounter, "Invalid product ID");
    ProductManufacturer memory product = products2[_productId];
    return (product.name, product.price, product.manufacturer, product.isPurchased);
    }

    function buyRawMaterial(uint256 _productId) payable public
    {
        //console.log("msg ",msg.value);
        manufacturing.buyRawMaterial(_productId,msg.value);
        payable(products[_productId].farmer).transfer(msg.value);
    }

    function buyManufactured(uint256 _productId) payable public
    {
        //console.log("msg ",msg.value);
        distributor.buyManufactured(_productId,msg.value);
        payable(products2[_productId].manufacturer).transfer(msg.value);
    }

    function updateRawMaterialPurchased(uint256 _productId, bool _isPurchased) public {
    require(_productId > 0 && _productId <= productIdCounter, "Invalid product ID");
    products[_productId].isPurchased = _isPurchased;
    }

    function updateMaufacturedPurchased(uint256 _productId, bool _isPurchased) public {
    require(_productId > 0 && _productId <= productIdCounter, "Invalid product ID");
    products2[_productId].isPurchased = _isPurchased;
  }
    event trace(uint FarmerPrice,address farmer,bool FarmerSold,uint ManufacturerPrice,address manufacturer, bool ManufacturerSold);
    function traceProductJourney(uint256 _productId) public returns(uint ,address , bool ,uint , address , bool)
    {
        
        (uint priceF,address farmer,bool SoldF,uint priceM,address manufacturer, bool SoldM)= 
        productTraceabilityModule.traceProductJourney(_productId);
        emit trace(priceF,farmer,SoldF,priceM,manufacturer, SoldM);
        return(priceF,farmer,SoldF,priceM,manufacturer, SoldM);
    }

    function storeRegulatoryDocuments(string memory _ruleDescription) public {
        complianceAndCertificationModule.setComplianceRule(_ruleDescription);
    }
    function getBalance(address x) public view returns (uint){
        return x.balance;
    }
}
