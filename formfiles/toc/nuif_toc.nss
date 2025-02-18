// ---------------------------------------------------------------------------------------
//                                  XXXXXXXX FORMFILE
// ---------------------------------------------------------------------------------------

// As of v1.0.0, all configuration options have been moved to a separate file to prevent
// overwriting server and system settings when new formfile versions are released.  The
// standard configuration file associated with this formfile is nuio_xxxx.nss.

// ---------------------------------------------------------------------------------------
//                          DO NOT MAKE ANY CHANGES BELOW THIS LINE
// ---------------------------------------------------------------------------------------

#include "nui_i_main"
#include "util_i_csvlists"
#include "util_i_debug"

const string VERSION = "1.0.0";
const string IGNORE_FORM_EVENTS = "mouseup,mousedown";

string _GetKey(string sPair)
{
    int nIndex;

    if ((nIndex = FindSubString(sPair, ":")) == -1)
        nIndex = FindSubString(sPair, "=");

    if (nIndex == -1) return sPair;
    else              return GetSubString(sPair, 0, nIndex);
}

string _GetValue(string sPair)
{
    int nIndex;

    if ((nIndex = FindSubString(sPair, ":")) == -1)
        nIndex = FindSubString(sPair, "=");

    if (nIndex == -1) return "";
    else              return GetSubString(sPair, ++nIndex, GetStringLength(sPair));
}

json CreateFormsList()
{
    NUI_CreateForm("");
        NUI_SetOrientation(NUI_ORIENTATION_ROWS);
    {
        sqlquery sqlForms = NUI_GetTOCForms();
        while (SqlStep(sqlForms))
        {
            string sTitle = SqlGetString(sqlForms, 0);
            string sFormID = SqlGetString(sqlForms, 1);

            NUI_AddRow();
            NUI_AddSpacer();
            NUI_AddCommandButton("open:" + sFormID);
                NUI_SetLabel(sTitle);
                NUI_SetWidth(275.0);
                NUI_SetHeight(45.0);
            NUI_AddImageButton("reload:" + sFormID);
                NUI_SetLabel("gui_mp_nowalkd");
                NUI_SetHeight(45.0);
                NUI_SetWidth(45.0);
            NUI_AddSpacer();
        }
    }

    return JsonObjectGet(NUI_GetBuildVariable(NUI_BUILD_ROOT), "root");
}

void NUI_HandleFormDefinition()
{
    string sFormID = "toc";

    NUI_CreateForm(sFormID);
        NUI_SetTitle("Available Forms");
        NUI_BindGeometry("geometry");
        NUI_SetOrientation(NUI_ORIENTATION_ROWS);
        NUI_SetResizable(TRUE);
    {
        NUI_AddRow();
        NUI_AddControlGroup();
            NUI_SetID("form_list");
            NUI_SetBorderVisible(FALSE);
            NUI_SetScrollbars(NUI_SCROLLBARS_AUTO);
        {
            NUI_AddSpacer();
        } NUI_CloseControlGroup();
    } NUI_SaveForm();
}

void UpdateBinds(string sBind, int nToken = -1, int bSetDefaults = FALSE)
{
    if (nToken == -1)
        nToken = NuiGetEventWindow();

    json jReturn = JsonNull();

    if (sBind == "geometry")
        jReturn = NUI_DefineRectangle(-1.0, -1.0, 375.0, 350.0);

    if (bSetDefaults == TRUE)
        NUI_DelayBindValue(OBJECT_SELF, nToken, sBind, jReturn);
    else
        NUI_SetBindValue(OBJECT_SELF, nToken, sBind, jReturn);
}

void NUI_HandleFormBinds(string sProfileName)
{


    object oPC = OBJECT_SELF;
    struct NUIBindData bd = NUI_GetBindData();
    int n;

    // Do form_open/default stuff here

    for (n = 0; n < bd.nCount; n++)
    {
        struct NUIBindArrayData bad = NUI_GetBindArrayData(bd.jBinds, n);
        UpdateBinds(bad.sBind, bd.nToken, TRUE);
    }
}

void NUI_HandleFormEvents()
{
    struct NUIEventData ed = NUI_GetEventData();
    NUI_Debug("Form Event (toc): " + ed.sEvent, NUI_DEBUG_SEVERITY_WARNING);

    if (HasListItem(IGNORE_FORM_EVENTS, ed.sEvent))
        return;

    if (ed.sEvent == "click")
    {
        string sKey = _GetKey(ed.sControlID);
        if (sKey == "open")
        {
            string sFormID = _GetValue(ed.sControlID);
            int n = NUI_DisplayForm(OBJECT_SELF, sFormID);
        }
        else if (sKey == "reload")
        {
            string sFormID = _GetValue(ed.sControlID);
            string sFormfile = NUI_GetFormfile(sFormID);   

            NUI_DefineFormsByFormfile(sFormfile);
            
            int nToken = NuiFindWindow(OBJECT_SELF, sFormID);
            if (nToken > 0)
            {
                NuiDestroy(OBJECT_SELF, nToken);
                NUI_DisplayForm(OBJECT_SELF, sFormID);
            }
        }
    }  
    else if (ed.sEvent == "open")
    {
        json jForms = CreateFormsList();
        int nToken = NuiFindWindow(OBJECT_SELF, "toc");
        NuiSetGroupLayout(OBJECT_SELF, nToken, "form_list", jForms);
    }
}

//void main() {}
