// package org.jdbc.examples.jdbcnative;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;

import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.UnmanagedMemory;
import org.graalvm.nativeimage.c.CContext;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;
import org.graalvm.nativeimage.c.struct.CField;
import org.graalvm.nativeimage.c.struct.CPointerTo;
import org.graalvm.nativeimage.c.struct.CStruct;
import org.graalvm.nativeimage.c.struct.SizeOf;
import org.graalvm.word.PointerBase;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;

import com.oracle.svm.core.c.ProjectHeaderFile;

@CContext(JdbcNativeLib.CInterfaceTutorialDirectives.class) 

public final class JdbcNativeLib {

    static class CInterfaceTutorialDirectives implements CContext.Directives {
		@Override
		public List<String> getHeaderFiles() {
			return Collections
				.singletonList(ProjectHeaderFile.resolve("org.jdbc.examples.jdbcnative", "record.h"));
		}
	}


    @CStruct("c_record")
	interface CRecordPointer extends PointerBase {

		@CField("cus_id")
        void setId(long cus_id);
        
		@CField("cus_name")
		CCharPointer getName();

		@CField("cus_name")
        void setName(CCharPointer cus_name);

        @CField("cus_age")
		void setAge(long cus_age);
        
		CRecordPointer addressOf(int index);
    }

    @CPointerTo(CRecordPointer.class)
	interface CRecordPointerPointer extends PointerBase {
		void write(CRecordPointer value);
    }

    @CEntryPoint(name = "exec_query_get_records")
	protected static int execQueryAndGetRecords(@SuppressWarnings("unused") IsolateThread thread, CCharPointer uri,
        CCharPointer user, CCharPointer password, CCharPointer query, CRecordPointerPointer out) {

        final String _uri = CTypeConversion.toJavaString(uri);
        final String _user = CTypeConversion.toJavaString(user);
        final String _password = CTypeConversion.toJavaString(password);
        final String _query = CTypeConversion.toJavaString(query);
        int size = 0;

        try (Connection connection = DriverManager.getConnection(_uri, _user, _password)) {
            Statement statement = connection.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
            ResultSet resultSet = statement.executeQuery(_query);

            List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
            ResultSetMetaData metaData = resultSet.getMetaData();
            int columnCount = metaData.getColumnCount();
            
            while (resultSet.next()) {
                Map<String, Object> columns = new LinkedHashMap<String, Object>();
            
                for (int i = 1; i <= columnCount; i++) {
                    columns.put(metaData.getColumnLabel(i), resultSet.getObject(i));
                }
                rows.add(columns);
            }
            CRecordPointer returnedRecords = UnmanagedMemory.calloc(rows.size() * SizeOf.get(CRecordPointer.class));
            int cnt = 0;
            long num;
            String s;

            for (Map<String, Object> map : rows) {
                CRecordPointer cRecord = returnedRecords.addressOf(cnt++);
                for (Map.Entry<String, Object> entry : map.entrySet()) {
                    String key = entry.getKey();
                    Object value = entry.getValue();

                    if (key.equals("cus_id")) {
                        s = String.valueOf(value);
                        num = Long.parseLong(s);
                        cRecord.setId(num);
                    }
                     else if (key.equals("cus_name")) {
                        s = value.toString();
                        cRecord.setName(toCCharPointer(s));
                    }
                     else if (key.equals("cus_age")) {
                        s = String.valueOf(value);
                        num = Long.parseLong(s);
                        cRecord.setAge(num);
                    } 
                }
            }

            out.write(returnedRecords);
            return cnt;
		}  catch (SQLException e) {
			System.out.println("Connection failure.");
			e.printStackTrace();
        }
        return 0;
    }
    private static CCharPointer toCCharPointer(String string) {
		byte[] bytes = string.getBytes(StandardCharsets.UTF_8);
		CCharPointer charPointer = UnmanagedMemory.calloc((bytes.length + 1) * SizeOf.get(CCharPointer.class));
		for (int i = 0; i < bytes.length; ++i) {
			charPointer.write(i, bytes[i]);
		}
		charPointer.write(bytes.length, (byte) 0);
		return charPointer;
    }
    @CEntryPoint(name = "free_results")
	protected static void freeResults(@SuppressWarnings("unused") IsolateThread thread, CRecordPointer results,
		int numResults) {
		for (int i = 0; i < numResults; ++i) {
			UnmanagedMemory.free(results.addressOf(i).getName());
		}
		UnmanagedMemory.free(results);
	}
	private JdbcNativeLib() {
	}
}
