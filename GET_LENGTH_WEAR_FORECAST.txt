create or replace PROCEDURE GET_LENGTH_WEAR_FORECAST (p_roll_type varchar2) AS 
-- declare
  TYPE colortype IS varray(16) OF VARCHAR2(7);
  --colors       COLORTYPE;
  v_str        VARCHAR2(32000);
  v_str1       VARCHAR2(32000);
  v_str2       VARCHAR2(32000);
  v_str3       VARCHAR2(32000);
  v_roll_type  VARCHAR2(100);
  v_status     NUMBER;
  --i            NUMBER;
  
BEGIN
    /*colors := Colortype('#7cb5ec', '#f45b5b', '#90ed7d', '#f7a35c', '#8085e9',
              '#f15c80','#e4d354', '#2b908f', '#00effe', '#dd7954','#c933ca','#0d238c',
              '#8bbc21', '#918835', '#492970', '#98434a');*/

    v_roll_type := p_roll_type;--apex_application.g_x01;

    v_str := '[';

    --i := 0;

    FOR r1 IN (SELECT DISTINCT rc.id_roll,rc.roll_supp
               FROM   v_roll_campaigns rc                  
               WHERE  rc.type_roll IN (SELECT Regexp_substr(v_roll_type,
                                                  '[^:]+'
                                                  , 1, LEVEL
                                                  )
                                           FROM   dual
                                           CONNECT BY Regexp_substr(v_roll_type,
                                                      '[^:]+', 1,
                                                      LEVEL) IS
                                                      NOT
                                                      NULL)) LOOP
        select sq.status into v_status from v_stock_of_rolls_forecast sq where sq.id_roll=r1.id_roll;
        if v_status <= 4 then 
        v_str1 := '{"name":"'
                  ||r1.id_roll||'"'
                  ||',"color": "'
                  ||/*Colors(i MOD 16 + 1)*/'#'||SUBSTR(DBMS_OBFUSCATION_TOOLKIT.MD5(INPUT => UTL_RAW.CAST_TO_RAW(r1.id_roll)),27,6)
                  ||'","dashStyle": "'
                  ||case when r1.roll_supp = 'AS' then 'DashDot'
                    when r1.roll_supp = 'GP' then 'LongDash'
                    when r1.roll_supp = 'KB' then 'LongDashDotDot'
                    else 'Solid'end
                  ||'",';
                  
        SELECT '"prognosis": "'
                  || case 
                  when remainder_km is null then -1 
                  else remainder_km end
                  ||'",'
                  ||'"act_wear": "'
                  ||vs.wear_prc
                  ||'"}'
                  into v_str3
                  from V_STOCK_OF_ROLLS_forecast vs 
                  where vs.id_roll = r1.id_roll;
        v_str := v_str
                 ||v_str1
                 ||v_str3
                 ||',';
        --i := i + 1;
        else null;
        end if;
    END LOOP;

    v_str := Rtrim(v_str, ',')
             ||']';

    htp.P(v_str);
    --dbms_output.put_line(v_str);
END GET_LENGTH_WEAR_FORECAST;