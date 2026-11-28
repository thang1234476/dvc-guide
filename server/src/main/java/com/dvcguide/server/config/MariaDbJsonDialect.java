package com.dvcguide.server.config;

import org.hibernate.dialect.MariaDBDialect;
import org.hibernate.engine.jdbc.dialect.spi.DialectResolutionInfo;
import org.hibernate.type.SqlTypes;

/**
 * MariaDB reports JSON columns as LONGVARCHAR because JSON is a LONGTEXT alias.
 */
public class MariaDbJsonDialect extends MariaDBDialect {
    public MariaDbJsonDialect() {
        super();
    }

    public MariaDbJsonDialect(DialectResolutionInfo info) {
        super(info);
    }

    @Override
    public boolean equivalentTypes(int first, int second) {
        return super.equivalentTypes(first, second)
                || (first == SqlTypes.JSON && second == SqlTypes.LONGVARCHAR)
                || (second == SqlTypes.JSON && first == SqlTypes.LONGVARCHAR);
    }
}
