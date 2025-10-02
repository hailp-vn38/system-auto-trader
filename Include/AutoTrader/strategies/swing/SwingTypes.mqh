//+------------------------------------------------------------------+
//| Include/AutoTrader/strategies/swing/SwingTypes.mqh               |
//| Common types and structures for swing-based strategies           |
//+------------------------------------------------------------------+
#ifndef SWING_TYPES_MQH
#define SWING_TYPES_MQH

//+------------------------------------------------------------------+
//| @brief Local extreme point structure                             |
//| @details Represents a swing high or swing low point with         |
//|          confirmation data                                       |
//+------------------------------------------------------------------+
struct LocalExtreme {
    int index;               ///< Index of the extreme point
    int ext_type;            ///< Extreme type (1: swing high, -1: swing low, 0: invalid)
    double price;            ///< Price at the extreme point
    datetime timestamp;      ///< Time at the extreme point
    double conf_price;       ///< Confirmation price (when swing was confirmed)
    datetime conf_timestamp; ///< Confirmation timestamp

    //+------------------------------------------------------------------+
    //| Default constructor                                              |
    //+------------------------------------------------------------------+
    LocalExtreme() {
        index          = -1;
        ext_type       = 0;
        price          = 0.0;
        timestamp      = 0;
        conf_price     = 0.0;
        conf_timestamp = 0;
    }

    //+------------------------------------------------------------------+
    //| Copy constructor                                                 |
    //+------------------------------------------------------------------+
    LocalExtreme(const LocalExtreme &other) {
        index          = other.index;
        ext_type       = other.ext_type;
        price          = other.price;
        timestamp      = other.timestamp;
        conf_price     = other.conf_price;
        conf_timestamp = other.conf_timestamp;
    }

    //+------------------------------------------------------------------+
    //| Check if the extreme point is valid                             |
    //+------------------------------------------------------------------+
    bool IsValid() const { return (ext_type != 0 && price > 0.0 && timestamp > 0); }

    //+------------------------------------------------------------------+
    //| Check if this is a swing high                                   |
    //+------------------------------------------------------------------+
    bool IsHigh() const { return ext_type == 1; }

    //+------------------------------------------------------------------+
    //| Check if this is a swing low                                    |
    //+------------------------------------------------------------------+
    bool IsLow() const { return ext_type == -1; }

    //+------------------------------------------------------------------+
    //| Compare with another LocalExtreme for equality                  |
    //+------------------------------------------------------------------+
    bool Compare(const LocalExtreme &other) const {
        return (ext_type == other.ext_type && MathAbs(price - other.price) < 0.00001
                && timestamp == other.timestamp);
    }

    //+------------------------------------------------------------------+
    //| Convert to string representation                                |
    //+------------------------------------------------------------------+
    string ToString() const {
        string type = (ext_type == 1) ? "High" : (ext_type == -1) ? "Low" : "Invalid";
        return StringFormat("Extreme[%s] Price=%.5f Time=%s Conf=%.5f@%s", type, price,
                            TimeToString(timestamp), conf_price, TimeToString(conf_timestamp));
    }
};

//+------------------------------------------------------------------+
//| @brief Container for extremes at a specific level                |
//| @details Manages a collection of LocalExtreme points for a       |
//|          particular market structure level                       |
//+------------------------------------------------------------------+
struct LevelExtremes {
    int level;               ///< Level identifier (0=base, 1+=higher levels)
    LocalExtreme extremes[]; ///< Dynamic array of extreme points

    //+------------------------------------------------------------------+
    //| Default constructor                                              |
    //+------------------------------------------------------------------+
    LevelExtremes() {
        level = 0;
        ArrayResize(extremes, 0);
    }

    //+------------------------------------------------------------------+
    //| Copy constructor                                                 |
    //+------------------------------------------------------------------+
    LevelExtremes(const LevelExtremes &other) {
        level    = other.level;
        int size = ArraySize(other.extremes);
        ArrayResize(extremes, size);
        for(int i = 0; i < size; i++) { extremes[i] = other.extremes[i]; }
    }

    //+------------------------------------------------------------------+
    //| Get total number of extremes                                    |
    //+------------------------------------------------------------------+
    int Size() const { return ArraySize(extremes); }

    //+------------------------------------------------------------------+
    //| Get extreme at index                                            |
    //+------------------------------------------------------------------+
    LocalExtreme At(const int index) const {
        if(index < 0 || index >= Size()) return LocalExtreme();
        return extremes[index];
    }

    //+------------------------------------------------------------------+
    //| Get the most recent extreme point                               |
    //+------------------------------------------------------------------+
    LocalExtreme GetLast() const { return (Size() > 0) ? extremes[Size() - 1] : LocalExtreme(); }

    //+------------------------------------------------------------------+
    //| Get the second most recent extreme                              |
    //+------------------------------------------------------------------+
    LocalExtreme GetPrevious() const {
        return (Size() > 1) ? extremes[Size() - 2] : LocalExtreme();
    }

    //+------------------------------------------------------------------+
    //| Add a new extreme point to the collection                       |
    //+------------------------------------------------------------------+
    bool Add(LocalExtreme &ext) {
        int newSize = ArraySize(extremes) + 1;
        if(ArrayResize(extremes, newSize) < 0) return false;

        ext.index             = newSize - 1;
        extremes[newSize - 1] = ext;
        return true;
    }

    //+------------------------------------------------------------------+
    //| Find an extreme point by its timestamp                          |
    //+------------------------------------------------------------------+
    int FindByTimestamp(const datetime time) const {
        for(int i = 0; i < Size(); i++) {
            if(extremes[i].timestamp == time) return i;
        }
        return -1;
    }

    //+------------------------------------------------------------------+
    //| Clear all extremes                                              |
    //+------------------------------------------------------------------+
    void Clear() { ArrayResize(extremes, 0); }
};

#endif // SWING_TYPES_MQH
