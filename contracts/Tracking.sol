// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Tracking {
    // enums
    enum ShipmentStatus {
        UNINITALIZED,
        PENDING,
        IN_TRANSIT,
        DELIVERED
    }

    // structs
    struct Shipment {
        uint256 uuid;
        address sender; // sending address
        address receiver; // receiving address
        uint256 pickupTime; // pickup time
        uint256 deliveryTime; // delivery time
        uint256 distance; // delivery distance
        uint256 price; // price
        ShipmentStatus status; // shipping status
        bool isPaid; // true if paid
    }

    // variables
    uint256 public _shipmentCount;
    Shipment[] public _allShipments;
    mapping(address => Shipment[]) public _shipments;

    // events
    event ShipmentCreated(
        address indexed sender,
        address indexed receiver,
        uint256 pickupTime,
        uint256 distance,
        uint256 price
    );
    event ShipmentInTransit(
        address indexed sender,
        address indexed receiver,
        uint256 pickupTime
    );
    event ShipmentDelivered(
        address indexed sender,
        address indexed receiver,
        uint256 deliveryTime
    );
    event ShipmentPaid(
        address indexed sender,
        address indexed reciver,
        uint256 amount
    );

    constructor() {}

    /**
        @dev    Create a shipment
    */
    function createShipment(
        address receiver_,
        uint256 pickupTime_,
        uint256 distance_,
        uint256 price_
    ) public payable {
        require(msg.value == price_, "Payment must equal price");
        Shipment memory shipment = Shipment(
            _shipmentCount,
            msg.sender,
            receiver_,
            pickupTime_,
            0,
            distance_,
            price_,
            ShipmentStatus.PENDING,
            false
        );
        _shipments[msg.sender].push(shipment);
        _shipmentCount++;
        _allShipments.push(shipment);

        emit ShipmentCreated(
            msg.sender,
            receiver_,
            pickupTime_,
            distance_,
            price_
        );
    }

    /**
        @dev    Start shipment
    */
    function startShipment(
        address sender_,
        address receiver_,
        uint256 index_
    ) public {
        Shipment storage shipment = _shipments[sender_][index_];

        require(shipment.receiver == receiver_, "Invalid receiver");
        require(
            shipment.status == ShipmentStatus.PENDING,
            "Shipment already in transit"
        );

        shipment.status = ShipmentStatus.IN_TRANSIT;
        _allShipments[shipment.uuid].status = ShipmentStatus.IN_TRANSIT;

        emit ShipmentInTransit(sender_, receiver_, shipment.pickupTime);
    }

    /**
        @dev    Complete shipment
    */
    function completeshipment(
        address sender_,
        address receiver_,
        uint256 index_
    ) public {
        Shipment storage shipment = _shipments[sender_][index_];

        require(shipment.receiver == receiver_, "Invalid receiver");
        require(
            shipment.status == ShipmentStatus.IN_TRANSIT,
            "Shipment not in transit"
        );
        require(!shipment.isPaid, "Shipment already paid.");

        shipment.status = ShipmentStatus.DELIVERED;
        _allShipments[shipment.uuid].status = ShipmentStatus.DELIVERED;

        shipment.deliveryTime = block.timestamp;
        _allShipments[shipment.uuid].deliveryTime = block.timestamp;

        uint256 amount = shipment.price;
        payable(shipment.sender).transfer(amount); // transfer amount to sender

        shipment.isPaid = true;
        _allShipments[shipment.uuid].isPaid = true;

        emit ShipmentDelivered(sender_, receiver_, shipment.deliveryTime);
        emit ShipmentPaid(sender_, receiver_, amount);
    }
}
