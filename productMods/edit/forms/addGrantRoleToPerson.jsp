<%-- $This file is distributed under the terms of the license in /doc/license.txt$ --%>

<%-- Custom form for adding a grant to an person for the predicates hasCo-PrincipalInvestigatorRole
     and hasPrincipalInvestigatorRole.
     
This is intended to create a set of statements like:

?person  core:hasPrincipalInvestigatorRole ?newRole.
?newRole rdf:type core:PrincipalInvestigatorRole ;
         core:relatedRole ?someGrant . 
--%>

<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>

<%@ page import="com.hp.hpl.jena.rdf.model.Model" %>
<%@ page import="com.hp.hpl.jena.vocabulary.XSD" %>

<%@ page import="edu.cornell.mannlib.vitro.webapp.beans.Individual" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.dao.VitroVocabulary" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.edit.n3editing.EditConfiguration" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.edit.n3editing.PersonHasPublicationValidator" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.dao.WebappDaoFactory" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.controller.VitroRequest" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.web.MiscWebUtils" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.controller.freemarker.UrlBuilder.JavaScript" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.controller.freemarker.UrlBuilder.Css" %>

<%@ page import="org.apache.commons.logging.Log" %>
<%@ page import="org.apache.commons.logging.LogFactory" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jstl/core"%>
<%@ taglib prefix="v" uri="http://vitro.mannlib.cornell.edu/vitro/tags" %>

<%! 
    public static Log log = LogFactory.getLog("edu.cornell.mannlib.vitro.webapp.jsp.edit.forms.addAuthorsToInformationResource.jsp");
%>
<%
    VitroRequest vreq = new VitroRequest(request);
    WebappDaoFactory wdf = vreq.getWebappDaoFactory();    
    vreq.setAttribute("defaultNamespace", ""); //empty string triggers default new URI behavior
    
    vreq.setAttribute("stringDatatypeUriJson", MiscWebUtils.escape(XSD.xstring.toString()));
    
    String intDatatypeUri = XSD.xint.toString();    
    vreq.setAttribute("intDatatypeUri", intDatatypeUri);
    vreq.setAttribute("intDatatypeUriJson", MiscWebUtils.escape(intDatatypeUri));
        
%>
<c:set var="vivoOnt" value="http://vivoweb.org/ontology" />
<c:set var="vivoCore" value="${vivoOnt}/core#" />
<c:set var="rdfs" value="<%= VitroVocabulary.RDFS %>" />
<c:set var="rdf" value="<%= VitroVocabulary.RDF %>" />
<c:set var="label" value="${rdfs}label" />


<%  // set role type based on predicate 
if ( ((String)request.getAttribute("predicateUri")).endsWith("hasPrincipalInvestigatorRole") ) { %>
 	<v:jsonset var="roleType">${vivoOnt}#PrincipalInvestigatorRole</v:jsonset>
 <% }else{ %>
 	<v:jsonset var="roleType">${vivoOnt}#hasCo-PrincipalInvestigatorRole</v:jsonset>
 <% } %>
 
<v:jsonset var="n3ForGrantRole">
    @prefix core: <${vivoCore}> .
    @prefix rdf: <${rdf}> .
    
	?person  ?rolePredicate ?role.
	?role rdf:type ?roleType ;
    	  core:relatedRole ?grant .               
</v:jsonset>

<v:jsonset var="n3ForNewGrant">
    @prefix core: <${vivoCore}> .
    @prefix rdf: <${rdf}> .
    @prefix rdfs: <${rdfs}> .
    	
    ?grant rdf:type core:Grant .
    ?grant rdfs:label ?grantLabel .               
</v:jsonset>

<%-- Must be all one line for JavaScript. --%>
<c:set var="sparqlForAcFilter">
PREFIX core: <${vivoCore}> SELECT ?grantURI WHERE {<${subjectUri}> core:hasPrincipalInvestigatorRole ?grantRole .?grantRole core:relatedRole ?grantURI .}
</c:set>

<v:jsonset var="grantTypeUriJson">${vivoOnt}#Grant</v:jsonset>
<c:set var="editjson" scope="request">
{
    "formUrl" : "${formUrl}",
    "editKey" : "${editKey}",
    "urlPatternToReturnTo" : "/individual", 

    "subject"   : ["person", "${subjectUriJson}" ],
    "predicate" : ["rolePredicate", "${predicateUriJson}" ],
    "object"    : ["role", "${objectUriJson}", "URI" ],
    
    "n3required"    : [ "${n3ForGrantRole}" ],
    
    "n3optional"    : [ "${n3ForNewGrant}" ],        
                                                                                        
    "newResources"  : { "role" : "${defaultNamespace}",
                        "grant" : "${defaultNamespace}" },

    "urisInScope"    : { "roleType" : "${roleType}" },
    "literalsInScope": { },
    "urisOnForm"     : [ "grant" ],
    "literalsOnForm" : [ "grantLabel" ],
    "filesOnForm"    : [ ],
    "sparqlForLiterals" : { },
    "sparqlForUris" : {  },
    "sparqlForExistingLiterals" : { },
    "sparqlForExistingUris" : { },
    "fields" : {  
      "grant" : {
         "newResource"      : "true",
         "validators"       : [ ],
         "optionsType"      : "UNDEFINED",
         "literalOptions"   : [ ],
         "predicateUri"     : "",
         "objectClassUri"   : "${grantTypeUriJson}",
         "rangeDatatypeUri" : "",
         "rangeLang"        : "",
         "assertions"       : [  ]
      },               
      "grantLabel" : {
         "newResource"      : "false",
         "validators"       :  [ "datatype:${stringDatatypeUriJson}" ],
         "optionsType"      : "UNDEFINED",
         "literalOptions"   : [ ],
         "predicateUri"     : "",
         "objectClassUri"   : "${personClassUriJson}",
         "rangeDatatypeUri" : "${stringDatatypeUriJson}",
         "rangeLang"        : "",         
         "assertions"       : ["${n3ForExistingPub}"]
      }
  }
}
</c:set>
   
<%
    log.debug(request.getAttribute("editjson"));

    EditConfiguration editConfig = EditConfiguration.getConfigFromSession(session,request);
    
    if (editConfig == null) {
        editConfig = new EditConfiguration((String) request.getAttribute("editjson"));     
        EditConfiguration.putConfigInSession(editConfig,session);
    }   
    
    //validator for addGrantRoleToPerson.jsp? 
	//editConfig.addValidator(new AddGrantRoleToPersonValidator());
        
    Model model = (Model) application.getAttribute("jenaOntModel");
    editConfig.prepareForNonUpdate(model); 
    
    //this will return the browser to the new grant entity after an edit.
    editConfig.setEntityToReturnTo("?grant");
    
    String subjectUri = vreq.getParameter("subjectUri");
    String predicateUri = vreq.getParameter("predicateUri");    
    String subjectName = ((Individual) request.getAttribute("subject")).getName();
  
    List<String> customJs = new ArrayList<String>(Arrays.asList(JavaScript.JQUERY_UI.path(),
                                                                JavaScript.UTILS.path(),
                                                                JavaScript.CUSTOM_FORM_UTILS.path(),
                                                                "/edit/forms/js/customFormWithAdvanceTypeSelection.js"
                                                               ));            
    request.setAttribute("customJs", customJs);
    
    List<String> customCss = new ArrayList<String>(Arrays.asList(Css.JQUERY_UI.path(),
                                                                 Css.CUSTOM_FORM.path(),
                                                                 "/edit/forms/css/autocomplete.css",
                                                                 "/edit/forms/css/customFormWithAdvanceTypeSelection.css"
                                                                ));                                                                                                                                   
    request.setAttribute("customCss", customCss); 
%>

<c:set var="requiredHint" value="<span class='requiredHint'> *</span>" />

<jsp:include page="${preForm}" />

<c:url var="acUrl" value="/autocomplete?stem=true" />
<c:url var="sparqlQueryUrl" value="/admin/sparqlquery" />
<script>
var customFormData  = {
    sparqlForAcFilter: '${sparqlForAcFilter}',
    sparqlQueryUrl: '${sparqlQueryUrl}',
    acUrl: '${acUrl}',
    acType: 'http://vivo.cornel.jdkjfldk#Grant'       
}
</script>

<h2>Create a new principal investigator entry for <%= subjectName %></h2>

<form id="addGrantRoleToPerson" action="<c:url value="/edit/processRdfForm2.jsp"/>" >
        
    <v:input type="text" id="label" name="grantLabel" label="Grant Name ${requiredHint}" cssClass="acSelector" size="50" />

    <div class="acSelection">
        <%-- RY maybe make this a label and input field. See what looks best. --%>
        <p class="inline"><label></label><span class="acSelectionInfo"></span></p>
        <%-- bdc34: for some odd reason id and name should not be grant in this input element. --%>
        <input type="hidden" id="pubUri" name="pubUri" class="acReceiver" value="" /> <!-- Field value populated by JavaScript -->
    </div>
            
    <p class="submit"><v:input type="submit" id="submit" value="Create principal investigator" cancel="true" /></p>
    
    <p id="requiredLegend" class="requiredHint">* required fields</p>
</form>

<jsp:include page="${postForm}"/>