/**
 * Copyright (C) 2017 Joshua Auerbach 
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.qcert.experimental.sql;

import java.lang.reflect.Method;
import java.util.EnumMap;
import java.util.List;

import org.apache.asterix.common.exceptions.CompilationException;
import org.apache.asterix.lang.common.base.Expression;
import org.apache.asterix.lang.common.base.Expression.Kind;
import org.apache.asterix.lang.common.base.ILangExpression;
import org.apache.asterix.lang.common.base.Literal;
import org.apache.asterix.lang.common.clause.GroupbyClause;
import org.apache.asterix.lang.common.clause.LetClause;
import org.apache.asterix.lang.common.clause.LimitClause;
import org.apache.asterix.lang.common.clause.OrderbyClause;
import org.apache.asterix.lang.common.clause.UpdateClause;
import org.apache.asterix.lang.common.clause.WhereClause;
import org.apache.asterix.lang.common.expression.CallExpr;
import org.apache.asterix.lang.common.expression.FieldAccessor;
import org.apache.asterix.lang.common.expression.IfExpr;
import org.apache.asterix.lang.common.expression.IndexAccessor;
import org.apache.asterix.lang.common.expression.ListConstructor;
import org.apache.asterix.lang.common.expression.LiteralExpr;
import org.apache.asterix.lang.common.expression.OperatorExpr;
import org.apache.asterix.lang.common.expression.OrderedListTypeDefinition;
import org.apache.asterix.lang.common.expression.QuantifiedExpression;
import org.apache.asterix.lang.common.expression.RecordConstructor;
import org.apache.asterix.lang.common.expression.RecordTypeDefinition;
import org.apache.asterix.lang.common.expression.TypeReferenceExpression;
import org.apache.asterix.lang.common.expression.UnaryExpr;
import org.apache.asterix.lang.common.expression.UnorderedListTypeDefinition;
import org.apache.asterix.lang.common.expression.VariableExpr;
import org.apache.asterix.lang.common.statement.CompactStatement;
import org.apache.asterix.lang.common.statement.ConnectFeedStatement;
import org.apache.asterix.lang.common.statement.CreateDataverseStatement;
import org.apache.asterix.lang.common.statement.CreateFeedPolicyStatement;
import org.apache.asterix.lang.common.statement.CreateFeedStatement;
import org.apache.asterix.lang.common.statement.CreateFunctionStatement;
import org.apache.asterix.lang.common.statement.CreateIndexStatement;
import org.apache.asterix.lang.common.statement.DatasetDecl;
import org.apache.asterix.lang.common.statement.DataverseDecl;
import org.apache.asterix.lang.common.statement.DataverseDropStatement;
import org.apache.asterix.lang.common.statement.DeleteStatement;
import org.apache.asterix.lang.common.statement.DisconnectFeedStatement;
import org.apache.asterix.lang.common.statement.DropDatasetStatement;
import org.apache.asterix.lang.common.statement.FeedDropStatement;
import org.apache.asterix.lang.common.statement.FeedPolicyDropStatement;
import org.apache.asterix.lang.common.statement.FunctionDecl;
import org.apache.asterix.lang.common.statement.FunctionDropStatement;
import org.apache.asterix.lang.common.statement.IndexDropStatement;
import org.apache.asterix.lang.common.statement.InsertStatement;
import org.apache.asterix.lang.common.statement.LoadStatement;
import org.apache.asterix.lang.common.statement.NodeGroupDropStatement;
import org.apache.asterix.lang.common.statement.NodegroupDecl;
import org.apache.asterix.lang.common.statement.Query;
import org.apache.asterix.lang.common.statement.SetStatement;
import org.apache.asterix.lang.common.statement.StartFeedStatement;
import org.apache.asterix.lang.common.statement.StopFeedStatement;
import org.apache.asterix.lang.common.statement.TypeDecl;
import org.apache.asterix.lang.common.statement.TypeDropStatement;
import org.apache.asterix.lang.common.statement.UpdateStatement;
import org.apache.asterix.lang.common.statement.WriteStatement;
import org.apache.asterix.lang.common.struct.OperatorType;
import org.apache.asterix.lang.common.struct.VarIdentifier;
import org.apache.asterix.lang.sqlpp.clause.FromClause;
import org.apache.asterix.lang.sqlpp.clause.FromTerm;
import org.apache.asterix.lang.sqlpp.clause.HavingClause;
import org.apache.asterix.lang.sqlpp.clause.JoinClause;
import org.apache.asterix.lang.sqlpp.clause.NestClause;
import org.apache.asterix.lang.sqlpp.clause.Projection;
import org.apache.asterix.lang.sqlpp.clause.SelectBlock;
import org.apache.asterix.lang.sqlpp.clause.SelectClause;
import org.apache.asterix.lang.sqlpp.clause.SelectElement;
import org.apache.asterix.lang.sqlpp.clause.SelectRegular;
import org.apache.asterix.lang.sqlpp.clause.SelectSetOperation;
import org.apache.asterix.lang.sqlpp.clause.UnnestClause;
import org.apache.asterix.lang.sqlpp.expression.CaseExpression;
import org.apache.asterix.lang.sqlpp.expression.IndependentSubquery;
import org.apache.asterix.lang.sqlpp.expression.SelectExpression;
import org.apache.asterix.lang.sqlpp.struct.SetOperationInput;
import org.apache.asterix.lang.sqlpp.struct.SetOperationRight;
import org.apache.asterix.lang.sqlpp.visitor.base.ISqlppVisitor;

public class SqlppEncodingVisitor implements ISqlppVisitor<StringBuilder, StringBuilder> {
	private static final EnumMap<OperatorType, String> opNameMap = new EnumMap<>(OperatorType.class);
	static {
		opNameMap.put(OperatorType.GT, "greater_than");
		opNameMap.put(OperatorType.EQ, "equal");
		// TODO the rest of these
	}
	
	public SqlppEncodingVisitor(boolean useDateNameHeuristic) {
		// TODO save argument for date processing later
	}

	@Override
	public StringBuilder visit(CallExpr pf, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(CaseExpression caseExpression, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(CompactStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(ConnectFeedStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(CreateDataverseStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(CreateFeedPolicyStatement cfps, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(CreateFeedStatement cfs, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(CreateFunctionStatement cfs, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(CreateIndexStatement cis, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(DatasetDecl dd, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(DataverseDecl dv, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(DataverseDropStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(DeleteStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(DisconnectFeedStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(DropDatasetStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(FeedDropStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(FeedPolicyDropStatement dfs, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(FieldAccessor fa, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(FromClause node, StringBuilder builder) throws CompilationException {
		builder.append("(from ");
		for (FromTerm term : node.getFromTerms())
			builder = term.accept(this, builder);
		return builder.append(") ");
	}

	@Override
	public StringBuilder visit(FromTerm node, StringBuilder builder) throws CompilationException {
		if (node.hasCorrelateClauses())
			throw new UnsupportedOperationException("Cannot handle correlate clauses in FromTerm");
		if (node.hasPositionalVariable())
			throw new UnsupportedOperationException("Cannot handle positional variables in FromTerm");
		VariableExpr var = node.getLeftVariable();
		Expression expr = node.getLeftExpression();
		boolean aliased = isDistinctName(var, expr);
		if (aliased)
			// Use 'aliasAs' for tables or subquery-like things, instead of 'as', which is used for columns.
			// This maintains the convention we had for Presto
			// TODO the distinction may or may not be useful ... check what happens on qcert side
			nodeWithString("aliasAs", decodeVariableRef(var.toString()), builder);
		if (expr.getKind() == Kind.VARIABLE_EXPRESSION)
			// Normal visit would use 'ref' but we want 'table' here to conform to our Presto encoding convention
			builder = appendStringNode("table", decodeVariableRef(expr.toString()), builder);
		else 
			builder = expr.accept(this, builder);
		return aliased ? builder.append(") ") : builder;
	}

	@Override
	public StringBuilder visit(FunctionDecl fd, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(FunctionDropStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(GroupbyClause gc, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(HavingClause havingClause, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(IfExpr ifexpr, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(IndependentSubquery independentSubquery, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(IndexAccessor ia, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(IndexDropStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(InsertStatement insert, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(JoinClause joinClause, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(LetClause lc, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(LimitClause lc, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(ListConstructor lc, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(LiteralExpr node, StringBuilder builder) throws CompilationException {
		Literal lit = node.getValue();
		switch (lit.getLiteralType()) {
		case INTEGER:
		case LONG:
		case STRING:
		case FALSE:
		case TRUE:
			return builder.append(lit.getStringValue()).append(" ");
		default:
			break;
		}
		throw new UnsupportedOperationException("Not supporting literals of type " + lit.getLiteralType());
	}

	@Override
	public StringBuilder visit(LoadStatement stmtLoad, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(NestClause nestClause, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(NodegroupDecl ngd, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(NodeGroupDropStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(OperatorExpr node, StringBuilder builder) throws CompilationException {
		List<Expression> exprs = node.getExprList();
		List<OperatorType> ops = node.getOpList();
		if (exprs.size() == 2 && ops.size() == 1)
			return processBinaryOperator(ops.get(0), exprs.get(0), exprs.get(1), builder);
		throw new UnsupportedOperationException("Not yet handling operator expressions that aren't binary");
	}

	@Override
	public StringBuilder visit(OrderbyClause oc, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(OrderedListTypeDefinition olte, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(Projection node, StringBuilder builder) throws CompilationException {
		Expression expr = node.getExpression();
		String name = node.getName();
		if (name != null && !isDistinctName(name, expr)) {
			name = null;
		}
		if (name != null) 
			appendStringNode("as", name, builder);
		if (expr != null)
			return expr.accept(this, builder);
		if (node.star())
			return builder.append("(all ) ");
		throw new UnsupportedOperationException("Cannot deal with a projection without an expression or a star");
	}

	@Override
	public StringBuilder visit(QuantifiedExpression qe, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(Query node, StringBuilder builder) throws CompilationException {
		if (node.getBody().getKind() != Kind.SELECT_EXPRESSION)
			throw new UnsupportedOperationException("Can't handle query whose body isn't a select expression");
		return node.getBody().accept(this, builder);
	}

	@Override
	public StringBuilder visit(RecordConstructor rc, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(RecordTypeDefinition tre, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(SelectBlock node, StringBuilder builder) throws CompilationException {
		builder.append("(query (select ");
		builder = node.getSelectClause().accept(this, builder);
		builder = builder.append(") "); // for parity with what Presto encoder does.
		builder = node.getFromClause().accept(this, builder);
		builder = acceptIfPresent(node.getWhereClause(), builder);
		builder = acceptIfPresent(node.getGroupbyClause(), builder);
		builder = acceptIfPresent(node.getHavingClause(), builder);
		return builder.append(") "); // only one since one was inserted above
	}

	@Override
	public StringBuilder visit(SelectClause node, StringBuilder builder) throws CompilationException {
		if (node.distinct())
			builder.append("(distinct) ");
		if (node.selectElement())
			builder = node.getSelectElement().accept(this, builder);
		if (node.selectRegular())
			builder = node.getSelectRegular().accept(this, builder);
		return builder;
	}

	@Override
	public StringBuilder visit(SelectElement selectElement, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(SelectExpression node, StringBuilder builder) throws CompilationException {
		builder = node.getSelectSetOperation().accept(this, builder);
		builder = acceptIfPresent(node.getOrderbyClause(), builder);
		return acceptIfPresent(node.getLimitClause(), builder);
	}

	@Override
	public StringBuilder visit(SelectRegular node, StringBuilder builder) throws CompilationException {
		for (Projection proj : node.getProjections()) {
			builder = proj.accept(this, builder);
		}
		return builder;
	}

	@Override
	public StringBuilder visit(SelectSetOperation node, StringBuilder builder) throws CompilationException {
		SetOperationInput first = node.getLeftInput();
		if (node.hasRightInputs()) {
			List<SetOperationRight> rights = node.getRightInputs();
			if (rights.size() > 1)
				throw new UnsupportedOperationException("No support for multiple right inputs in a SelectSetOperation");
			SetOperationRight rightInput = rights.get(0);
			SetOperationInput second = rightInput.getSetOperationRightInput();
			boolean distinct = rightInput.isSetSemantics();
			String tag;
			switch (rightInput.getSetOpType()) {
			case INTERSECT:
				tag = "intersect";
				break;
			case UNION:
				tag = "union";
				break;
			default:
				throw new UnsupportedOperationException("No support for operator: " + rightInput.getSetOpType());
			}
			builder = builder.append("(query (").append(tag).append(distinct ? " (distinct) " : " ");
			builder = first.accept(this, builder);
			return second.accept(this, builder).append(") ) ");
		} else
			return node.getLeftInput().accept(this, builder);
	}

	@Override
	public StringBuilder visit(SetStatement ss, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(StartFeedStatement sfs, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(StopFeedStatement sfs, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(TypeDecl td, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(TypeDropStatement del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(TypeReferenceExpression tre, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(UnaryExpr u, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(UnnestClause unnestClause, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(UnorderedListTypeDefinition ulte, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(UpdateClause del, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(UpdateStatement update, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	@Override
	public StringBuilder visit(VariableExpr node, StringBuilder builder) throws CompilationException {
		String name = node.getVar().toString();
		return appendStringNode("ref", decodeVariableRef(name), builder);
	}

	@Override
	public StringBuilder visit(WhereClause node, StringBuilder builder) throws CompilationException {
    	builder.append("(where ");
    	builder = node.getWhereExpr().accept(this, builder);
    	return builder.append(") ");
	}

	@Override
	public StringBuilder visit(WriteStatement ws, StringBuilder arg) throws CompilationException {
		return notImplemented(new Object(){});
	}

	private StringBuilder acceptIfPresent(ILangExpression node, StringBuilder builder) throws CompilationException {
		if (node != null)
			builder = node.accept(this, builder);
		return builder;
	}

	/**
	 * Given a node name and a string argument, append a String-style S-expression node
	 * @param node the node name
	 * @param arg the String argument
	 * @param builder the StringBuilder to receive the append
	 */
	private StringBuilder appendStringNode(String node, String arg, StringBuilder builder) {
		return builder.append(String.format("(%s \"%s\" ) ", node, arg));
	}

	/**
	 * Reverse the asterixDB practice of prefixing variable references with '$'
	 * @param name the name to decode
	 * @return the decoded name
	 */
	private String decodeVariableRef(String name) {
		return (name.charAt(0) == '$') ? name.substring(1) : name;
	}

	/**
	 * Work around the asterixDB convention of including an explicit name for every selected column, even when that is the
	 *   same as the name of column. 
	 * @param name the name assigned to the column
	 * @param expr the Expression for the column, which might be a variable reference and possible to the same name, though
	 *   prefixed with a $ as per their convention
	 * @return true iff the name is distinct (that is, requires explicit handling in an "as" clause, otherwise such handling can be
	 *   omitted to match presto conventions)
	 */
	private boolean isDistinctName(String name, Expression expr) {
		if (expr.getKind() == Kind.VARIABLE_EXPRESSION) {
			VariableExpr var = (VariableExpr) expr;
			if (var.getIsNewVar())
				return true;
			VarIdentifier id = var.getVar();
			if (id.namedValueAccess())
				return true;
			String exprName = id.getValue();
			if (exprName.length() == name.length() + 1 && decodeVariableRef(exprName).equals(name))
				return false;
		}
		return true;
	}

	/**
	 * Work around the asterixDB convention of including an explicit name for every selected-from table, even when that is the
	 *   same as the name of table (dual of similar method for columns) 
	 * @param var the name for the table as a VariableExpr
	 * @param expr the Expression for the table, which might be a variable reference and possible to the same name, though
	 *   prefixed with a $ as per their convention
	 * @return true iff the name is distinct (that is, requires explicit handling in an "as" clause, otherwise such handling can be
	 *   omitted to match presto conventions)
	 */
	private boolean isDistinctName(VariableExpr name, Expression expr) {
		VarIdentifier id = name.getVar();
		if (id.namedValueAccess())
			return true;
		String varName = decodeVariableRef(id.getValue());
		return isDistinctName(varName, expr);
	}

	/** Like appendStringNode but leaves the node open for more things to be added (see appendStringNode) */
	private StringBuilder nodeWithString(String node, String arg, StringBuilder builder) {
		return builder.append(String.format("(%s \"%s\" ", node, arg));
	}
	
	private StringBuilder notImplemented(Object o) {
		Method method = o.getClass().getEnclosingMethod();
		Class<?> type = method.getParameterTypes()[0];
		throw new UnsupportedOperationException("Visitor not implemented for " + type.getSimpleName());
	}

	private StringBuilder processBinaryOperator(OperatorType operator, Expression operand1, Expression operand2, StringBuilder builder) 
			throws CompilationException {
		String verb = opNameMap.get(operator);
		if (verb == null)
			throw new UnsupportedOperationException("No support for binary operator " + operator);
		// TODO date expression substitution needed here
		builder.append("(").append(verb).append(" ");
		builder = operand1.accept(this, builder);
		builder = operand2.accept(this, builder);
		return builder.append(") ");
	}
}
