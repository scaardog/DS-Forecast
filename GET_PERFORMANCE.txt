create or replace PROCEDURE GET_PERFORMANCE (p_xaxis varchar2,
                                             p_yaxis varchar2,
                                             p_f_rolltype varchar2, 
                                             p_f_status varchar2,
                                             p_f_quality varchar2,
                                             p_f_supplier varchar2,
                                             p_groups varchar2,
                                             p_aggregate varchar2,
                                             p_period varchar2,
                                             p_f_position varchar2,
                                             p_period_start varchar2,
                                             p_period_finish varchar2) AS 
v_str varchar2(32000);
v_str1 varchar2(32000);
v_str2 varchar2(1000);

v_xaxis varchar2(200);
v_yaxis varchar2(100);

v_tons_or_km varchar2(50); -- variables for performance values when grouping by period
v_act_or_norm varchar2(50);

v_query varchar2(3000);
v_aggregates varchar2(100);

v_period varchar2(100);

v_f_position varchar2(20);

BEGIN
  v_str:='[';
  
  v_yaxis:=p_yaxis; 
  v_xaxis:=p_xaxis; 
  
  v_f_position:=REPLACE(p_f_position,':','|');
  
  if v_xaxis = 'ID_ROLL_SUPP'
  then v_xaxis:=' Decode('||p_xaxis||',''AS'',1,''KB'',2,''GP'',3,4)';
  elsif  v_xaxis = 'ROLL_LAST_POSITION'
  then v_xaxis:=' Decode('||p_xaxis||',''TOP'',1,''BOT'',2,3)' ;
  else
  v_xaxis:= 'Replace(Round('||p_xaxis||'),'','', ''.'')';
  end if;
  
  if v_yaxis = 'TONNES_PER_MM' or v_yaxis = 'TONNES_PER_MM_NORM'
  then v_tons_or_km:= 'TONS_ROLLED';
  else v_tons_or_km:='LENGTH_ROLLED';
  end if;
  
  if v_yaxis = 'ROLLED_KM_PER_MM_NORM' or v_yaxis = 'TONNES_PER_MM_NORM'
  then v_act_or_norm:= 'WEAR_MM_NORM';
  else v_act_or_norm:='WEAR_MM';
  end if;
  
  if p_period = 1 then v_period := 'year_';
  elsif p_period = 2 then v_period := 'quarter_ ||''/''|| year_';
  elsif p_period = 3 then v_period := 'month_ ||''/''|| year_';
  end if;
  
  if p_groups = '0' then
    v_query:='insert into GET_PERFORMANCE_RAWDATA (V_NAME,V_COLOR,V_X,V_Y)
    select id_roll,
           ''#''||SUBSTR(DBMS_OBFUSCATION_TOOLKIT.MD5(INPUT => UTL_RAW.CAST_TO_RAW(id_roll)),27,6),'
           ||v_xaxis
           ||','
           ||v_yaxis
           ||
    ' from v_stock_of_rolls
    where Nvl(length_rolled,0)>0
    and REGEXP_LIKE(TYPE_ROLL,''[''||:1||'']'',''i'')
    and REGEXP_LIKE(STATUS,''[''||:2||'']'',''i'')
    and REGEXP_LIKE(QUALITY_ROLL,''[''||:3||'']'',''i'')
    and REGEXP_LIKE(ID_ROLL_SUPP,''[''||:4||'']'',''i'')
    and REGEXP_LIKE(ROLL_LAST_POSITION,:5,''i'')';
  elsif p_groups = 'Period' then
  --
    v_query:=
    'insert into GET_PERFORMANCE_RAWDATA (V_NAME,V_COLOR,V_X,V_MAX,V_AVG,V_MIN)
    select '||v_period||',
    ''#''||SUBSTR(DBMS_OBFUSCATION_TOOLKIT.MD5(INPUT => UTL_RAW.CAST_TO_RAW('||v_period||')),27,6) as color,
    '||v_period||',
    Round(MAX('||v_tons_or_km||'/nullif('||v_act_or_norm||',0))), 
    Round(AVG('||v_tons_or_km||'/nullif('||v_act_or_norm||',0))),
    Round(MIN('||v_tons_or_km||'/nullif('||v_act_or_norm||',0)))
    from
    (select rc.id_roll, 
     rc.TONS_ROLLED,
     rc.LENGTH_ROLLED,
     rc.WEAR_MM,
     rc.WEAR_MM_NORM,
     to_char(DISMOUNT_TIME,''Q'') as quarter_,
     Extract(month from (DISMOUNT_TIME)) as month_,
     Extract(year from (DISMOUNT_TIME)) as year_
     from V_ROLL_CAMPAIGNS rc 
     join v_stock_of_rolls sr 
     on rc.id_roll = sr.id_roll  
     where dismount_time is not null
     and REGEXP_LIKE(rc.TYPE_ROLL,''[''||:1||'']'',''i'')
     and REGEXP_LIKE(sr.STATUS,''[''||:2||'']'',''i'')
     and REGEXP_LIKE(rc.QUALITY_ROLL,''[''||:3||'']'',''i'')
     and REGEXP_LIKE(sr.ID_ROLL_SUPP,''[''||:4||'']'',''i'')
     and REGEXP_LIKE(sr.ROLL_LAST_POSITION,:5,''i'')
     and dismount_time between case when '||p_period_start||' is not null 
                                    then to_date('''||p_period_start||''',''dd-mm-yyyy'') 
                                    else to_date(''01-01-2014'',''dd-mm-yyyy'') end 
                               and
                               case when '||p_period_finish||' is not null
                                    then to_date('''||p_period_finish||''',''dd-mm-yyyy'') 
                                    else sysdate end
    )
  where TONS_ROLLED/nullif(WEAR_MM,0) is not null
  group by '||v_period;
  --
  else
    v_query:='insert into GET_PERFORMANCE_RAWDATA (V_NAME,V_COLOR,V_X,V_MAX,V_AVG,V_MIN)
    select '||p_groups
            ||','
            ||'''#''||SUBSTR(DBMS_OBFUSCATION_TOOLKIT.MD5(INPUT => UTL_RAW.CAST_TO_RAW('||p_groups||')),27,6), '
            ||v_xaxis
            ||','
            ||'max('||v_yaxis||')'
            ||','
            ||'avg('||v_yaxis||')'
            ||','
            ||'min('||v_yaxis||')'
            ||
    ' from v_stock_of_rolls
    where Nvl(length_rolled,0)>0
    and REGEXP_LIKE(TYPE_ROLL,''[''||:1||'']'',''i'')
    and REGEXP_LIKE(STATUS,''[''||:2||'']'',''i'')
    and REGEXP_LIKE(QUALITY_ROLL,''[''||:3||'']'',''i'')
    and REGEXP_LIKE(ID_ROLL_SUPP,''[''||:4||'']'',''i'')
    and REGEXP_LIKE(ROLL_LAST_POSITION,:5,''i'')
    group by '||p_groups;
  end if;
  
  execute immediate --dymanic query that populates temp table
  v_query using p_f_rolltype,p_f_status,p_f_quality,p_f_supplier,v_f_position;
  
  IF p_groups ='0'
  THEN
    select Listagg('{"name":"'  --forming string output
                    ||v_name
                    ||'", "color":"'
                    ||v_color
                    ||'", "data":[['
                    ||v_x
                    ||','
                    ||v_y
                    ||']]}', ',')
    WITHIN GROUP (ORDER BY v_name)
    INTO   v_str1
    FROM   GET_PERFORMANCE_RAWDATA;
  -- 
  ELSIF p_groups='Period' 
  THEN
    for r1 in (select v_name from get_performance_rawdata)loop
    select '{"name":"'  --forming string output
                    ||v_name
                    ||'", "color":"'
                    ||v_color
                    ||'", "data":['
                    ||case when REGEXP_LIKE('1','['||p_aggregate||']','i') then
                    '["'
                    ||v_x
                    ||'",'
                    ||v_max
                    ||']'
                    end
                    ||case when REGEXP_LIKE('2','['||p_aggregate||']','i') then
                    case when REGEXP_LIKE('1','['||p_aggregate||']','i') then ',' end
                    ||'["'
                    ||v_x
                    ||'",'
                    ||Round(v_avg)
                    ||']'
                    end
                    ||case when REGEXP_LIKE('3','['||p_aggregate||']','i') then
                    case when REGEXP_LIKE('1:2','['||p_aggregate||']','i') then ',' end
                    ||'["'
                    ||v_x
                    ||'",'
                    ||v_min
                    ||']'
                    end
                    ||']},'

    INTO   v_str2
    FROM   GET_PERFORMANCE_RAWDATA
    where v_name = r1.v_name;
    
    v_str1:=v_str1||v_str2;
    end loop;
  v_str1 := Rtrim(v_str1, ',');
  --
  ELSE
  for r1 in (select v_name from get_performance_rawdata)loop
    select '{"name":"'  --forming string output
                    ||v_name
                    ||'", "color":"'
                    ||v_color
                    ||'", "data":['
                    ||case when REGEXP_LIKE('1','['||p_aggregate||']','i') then
                    '['
                    ||v_x
                    ||','
                    ||v_max
                    ||']'
                    end
                    ||case when REGEXP_LIKE('2','['||p_aggregate||']','i') then
                    case when REGEXP_LIKE('1','['||p_aggregate||']','i') then ',' end
                    ||'['
                    ||v_x
                    ||','
                    ||Round(v_avg)
                    ||']'
                    end
                    ||case when REGEXP_LIKE('3','['||p_aggregate||']','i') then
                    case when REGEXP_LIKE('1:2','['||p_aggregate||']','i') then ',' end
                    ||'['
                    ||v_x
                    ||','
                    ||v_min
                    ||']'
                    end
                    ||']},'

    INTO   v_str2
    FROM   GET_PERFORMANCE_RAWDATA
    where v_name = r1.v_name;
    
    
    v_str1:=v_str1||v_str2;
    end loop;
  v_str1 := Rtrim(v_str1, ',');
  END IF;
  v_str:=v_str||v_str1||']';
  
  htp.p(v_str);
  --dbms_output.put_line(v_str);
END GET_PERFORMANCE;