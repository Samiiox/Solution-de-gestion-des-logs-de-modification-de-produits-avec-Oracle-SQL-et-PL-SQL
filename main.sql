DROP TRIGGER product_log;
DROP TRIGGER product_log_proc;
DROP TRIGGER product_log_log2;

DROP TABLE product_log;
DROP TABLE product_log_procc;
DROP TABLE product_log2_delete;
DROP TABLE product_log2_insert;
DROP TABLE product_log2_update;



--//1er version


CREATE TABLE product (
    id    NUMBER(8)
        GENERATED ALWAYS AS IDENTITY START WITH 100 INCREMENT BY 1
    PRIMARY KEY,
    name  VARCHAR2(20),
    price NUMBER(10, 2)
);



CREATE TABLE product_log (
    skey1          NUMBER(8)
        GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1
    PRIMARY KEY,
    id             NUMBER(8),
    name           VARCHAR2(20),
    previous_price NUMBER(10, 2),
    price          NUMBER(10, 2),
    date_effective TIMESTAMP(0) ,
    date_retrait   TIMESTAMP(0) ,
    indicateur NUMBER(5)
);



CREATE OR REPLACE TRIGGER product_log AFTER
    UPDATE ON product
    FOR EACH ROW
BEGIN
    IF :new.price = :old.price THEN
        raise_application_error(-20002, 'La nouvelle valeur de prix est identique à l''ancienne valeur de prix.');
    ELSE
        IF :new.price <= 0 THEN
            raise_application_error(-20003, 'La nouvelle valeur de prix ne peut pas etre inferieur ou egale a 0.');
        ELSE
            UPDATE product_log
            SET
                indicateur = 0
            WHERE
                    id = :new.id
                AND indicateur = 1;

            UPDATE product_log
            SET
                date_retrait = trunc(systimestamp, 'MI')
            WHERE
                date_retrait IS NULL
                AND id = :new.id;

            INSERT INTO product_log (
                id,
                name,
                previous_price,
                price,
                date_effective,
                date_retrait,
                indicateur
            ) VALUES (
                :new.id,
                :new.name,
                :old.price,
                :new.price,
                trunc(systimestamp, 'MI'),
                NULL,
                1
            );

        END IF;
    END IF;
END;




INSERT INTO product (name,price) VALUES ('Product 1',99.99);
INSERT INTO product (name,price) VALUES ('Product 2',99.99);
INSERT INTO product (name,price) VALUES ('Product 3',99.99);
INSERT INTO product (name,price) VALUES ('Product 4',99.99);
INSERT INTO product (name,price) VALUES ('Product 5',99.99);
INSERT INTO product (name,price) VALUES ('Product 6',99.99);


UPDATE product SET price = 109.99 WHERE id = 101;

DELETE FROM product
WHERE
    id = 101;


--//2éme version (meme fonctionnaliter que la 1er mais avec une proceedure)

CREATE TABLE product_log_procc (
    skey1          NUMBER(8)
        GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1
    PRIMARY KEY,
    id             NUMBER(8),
    name           VARCHAR2(20),
    previous_price NUMBER(10, 2),
    price          NUMBER(10, 2),
    date_effective TIMESTAMP(0) ,
    date_retrait   TIMESTAMP(0) ,
    indicateur NUMBER(5)
);



CREATE OR REPLACE PROCEDURE product_log_procd (
    p_id      product.id%TYPE,
    new_price product.price%TYPE,
    old_price product.price%TYPE,
    p_name    product.name%TYPE
) IS
BEGIN
    UPDATE product_log_procc
    SET
        indicateur = 0
    WHERE
            id = p_id
        AND indicateur = 1;

    UPDATE product_log_procc
    SET
        date_retrait = trunc(systimestamp, 'MI')
    WHERE
        date_retrait IS NULL
        AND id = p_id;

    INSERT INTO product_log_procc (
        id,
        name,
        previous_price,
        price,
        date_effective,
        date_retrait,
        indicateur
    ) VALUES (
        p_id,
        p_name,
        old_price,
        new_price,
        trunc(systimestamp, 'MI'),
        NULL,
        1
    );

END;



CREATE OR REPLACE TRIGGER product_log_proc AFTER
    UPDATE ON product
    FOR EACH ROW
BEGIN
    IF :new.price = :old.price THEN
        raise_application_error(-20002, 'La nouvelle valeur de prix est identique à l''ancienne valeur de prix.');
    ELSE
        IF :new.price <= 0 THEN
            raise_application_error(-20003, 'La nouvelle valeur de prix ne peut pas etre inferieur ou egale a 0.');
        ELSE
            product_log_procd(p_name => :new.name, new_price => :new.price, old_price => :old.price, p_id => :new.id);
        END IF;
    END IF;
END;






--//3éme version (plus de  fonctionnaliter)


CREATE TABLE product_log2_update (
    skey1          NUMBER(8)
        GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1
    PRIMARY KEY,
    id             NUMBER(8),
    name           VARCHAR2(20),
    previous_price NUMBER(10, 2),
    price          NUMBER(10, 2),
    date_effective TIMESTAMP,
    date_retrait   TIMESTAMP,
    indicateur     NUMBER(5),
    op_user        VARCHAR2(20),
	price_variation  VARCHAR2(50),
	ip_address     VARCHAR2(50)
);



CREATE TABLE product_log2_delete (
    skey1          NUMBER(8)
        GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1
    PRIMARY KEY,
    id             NUMBER(8),
    name           VARCHAR2(20),
    previous_price NUMBER(10, 2),
    op_date        TIMESTAMP(0),
    op_user        VARCHAR2(20),
	ip_address     VARCHAR2(50)
);



CREATE TABLE product_log2_insert (
    skey1   NUMBER(8)
        GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1
    PRIMARY KEY,
    id      NUMBER(8),
    name    VARCHAR2(20),
    price   NUMBER(10, 2),
    op_date TIMESTAMP(0),
    op_user VARCHAR2(20),
	ip_address     VARCHAR2(50)
);



CREATE OR REPLACE TRIGGER product_log2 AFTER
    DELETE OR INSERT OR UPDATE ON product
    FOR EACH ROW
BEGIN
    IF inserting THEN
        IF :new.price <= 0 THEN
            raise_application_error(-20002, 'La  valeur de prix ne peut pas etre inferieur ou egale a 0.');
        ELSE
            INSERT INTO product_log2_insert (
                id,
                name,
                price,
                op_date,
                op_user,
                ip_address
            ) VALUES (
                :new.id,
                :new.name,
                :new.price,
                trunc(systimestamp, 'MI'),
                user,
                sys_context('USERENV', 'IP_ADDRESS')
            );

        END IF;

    ELSIF updating THEN
        IF :new.price = :old.price THEN
            raise_application_error(-20002, 'La nouvelle valeur de prix est identique à l''ancienne valeur de prix.');
        ELSE
            IF :new.price <= 0 THEN
                raise_application_error(-20003, 'La nouvelle valeur de prix ne peut pas etre inferieur ou egale a 0.');
            ELSE
                UPDATE product_log2_update
                SET
                    indicateur = 0
                WHERE
                        id = :new.id
                    AND indicateur = 1;

                UPDATE product_log2_update
                SET
                    date_retrait = trunc(systimestamp, 'MI')
                WHERE
                    date_retrait IS NULL
                    AND id = :new.id;

                INSERT INTO product_log2_update (
                    id,
                    name,
                    previous_price,
                    price,
                    date_effective,
                    date_retrait,
                    indicateur,
                    op_user,
                    ip_address
                ) VALUES (
                    :new.id,
                    :new.name,
                    concat(:old.price, '$'),
                    concat(:new.price, '$'),
                    trunc(systimestamp, 'MI'),
                    NULL,
                    1,
                    user,
                    sys_context('USERENV', 'IP_ADDRESS')
                );

                UPDATE product_log2_update
                SET
                    price_variation =
                        CASE
                            WHEN :new.price - :old.price < 0 THEN
                                concat('-', concat(abs(:new.price - :old.price), '$'))
                            ELSE
                                concat('+', concat(abs(:new.price - :old.price), '$'))
                        END
                WHERE
                        id = :new.id
                    AND indicateur = 1;

            END IF;
        END IF;
    ELSIF deleting THEN
        INSERT INTO product_log2_delete (
            id,
            name,
            previous_price,
            op_date,
            op_user,
            ip_address
        ) VALUES (
            :old.id,
            :old.name,
            :old.price,
            trunc(systimestamp, 'MI'),
            user,
            sys_context('USERENV', 'IP_ADDRESS')
        );

    END IF;
END;
